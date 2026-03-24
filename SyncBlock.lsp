;;; ============================================================
;;; SyncBlock.lsp v12-AttSync
;;; 新增：完整屬性定義同步 + 自動 ATTSYNC（無對話框）
;;; 優化：幾何與屬性分開處理、BBox 只算幾何、效能更高
;;; 指令：SyncNow 或 SFM
;;; ============================================================
(vl-load-com)

(defun get-objects-bbox (objList / minPt ll ur)
  (if (null objList)
    nil
    (progn
      (setq minPt (list 1e99 1e99 0.0))
      (foreach obj objList
        (if (not (vl-catch-all-error-p
                   (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
          (progn
            (setq ll (vlax-safearray->list ll))
            (setq minPt (mapcar 'min minPt ll))
          )
        )
      )
      (if (= (car minPt) 1e99) nil minPt)
    )
  )
)

(defun c:SyncNow ( / acadObj doc blocks
                    masterEnt masterVla masterName masterDef
                    targetSS i targetEnt targetVla targetName targetDef
                    layerList layColorMap geometryToCopy attDefsToCopy objsToCopy
                    targetGeometry minPtA minPtB dX dY dZ copyRes pt1 pt2
                    oldEcho lay mappedCol objName )

  (setq acadObj (vlax-get-acad-object)
        doc     (vla-get-ActiveDocument acadObj)
        blocks  (vla-get-Blocks doc))

  ;; ── 1. 選擇主底圖 Block A ──────────────────────────────
  (if (not (setq masterEnt (car (entsel "\n【SyncBlock-AttSync】點選主底圖 Block A: "))))
    (progn (princ "\n取消。") (exit))
  )
  (setq masterVla (vlax-ename->vla-object masterEnt))
  (if (/= (vla-get-ObjectName masterVla) "AcDbBlockReference")
    (progn (princ "\n所選物件不是 Block。") (exit))
  )
  (setq masterName (vla-get-EffectiveName masterVla)
        masterDef  (vla-Item blocks masterName))
  (princ (strcat "\n✔ 主底圖：" masterName))

  ;; ── 2. 框選目標 Block ──────────────────────────────────
  (princ "\n\n框選所有目標 Block (可多選): ")
  (if (not (setq targetSS (ssget '((0 . "INSERT")))))
    (progn (princ "\n取消。") (exit))
  )

  ;; ── 3. 開始處理 ────────────────────────────────────────
  (vla-StartUndoMark doc)
  (setq oldEcho (getvar 'cmdecho))
  (setvar 'cmdecho 0)   ; 讓 ATTSYNC 安靜執行
  (setq i 0)

  (while (< i (sslength targetSS))
    (setq targetEnt  (ssname targetSS i)
          targetVla  (vlax-ename->vla-object targetEnt)
          targetName (vla-get-EffectiveName targetVla))

    (if (= targetName masterName)
      (princ (strcat "\n跳過相同 Block：" targetName))
      (progn
        (princ (strcat "\n處理 → " targetName " ..."))
        (setq targetDef (vla-Item blocks targetName))

        ;; === 1. 一次收集目標的圖層、顏色、幾何物件 ===
        (setq layerList '() layColorMap '() targetGeometry '())
        (vlax-for obj targetDef
          (setq lay (vla-get-Layer obj))
          (if (not (member lay layerList))
            (setq layerList (cons lay layerList))
          )
          (if (and (not (assoc lay layColorMap))
                   (not (vl-catch-all-error-p
                          (setq col (vl-catch-all-apply 'vla-get-Color (list obj))))))
            (setq layColorMap (cons (cons lay col) layColorMap))
          )
          (if (/= (vla-get-ObjectName obj) "AcDbAttributeDefinition")
            (setq targetGeometry (cons obj targetGeometry))
          )
        )

        ;; 計算目標幾何 BBox
        (setq minPtB (get-objects-bbox targetGeometry))

        ;; === 2. 從 Master 收集：幾何（依圖層） + 全部屬性 ===
        (setq geometryToCopy '() attDefsToCopy '())
        (vlax-for obj masterDef
          (setq objName (vla-get-ObjectName obj))
          (if (= objName "AcDbAttributeDefinition")
            (setq attDefsToCopy (cons obj attDefsToCopy))
            (if (member (vla-get-Layer obj) layerList)
              (setq geometryToCopy (cons obj geometryToCopy))
            )
          )
        )

        (setq objsToCopy (append geometryToCopy attDefsToCopy))

        ;; 計算 Master 幾何 BBox
        (setq minPtA (get-objects-bbox geometryToCopy))

        ;; 計算位移（只依幾何）
        (setq dX 0.0 dY 0.0 dZ 0.0)
        (if (and minPtA minPtB)
          (setq dX (- (car minPtB) (car minPtA))
                dY (- (cadr minPtB) (cadr minPtA))
                dZ (- (caddr minPtB) (caddr minPtA)))
        )

        ;; 清空目標 Block（同時清除舊屬性）
        (vlax-for obj targetDef
          (vl-catch-all-apply 'vla-Delete (list obj))
        )

        ;; 複製（幾何 + 屬性）
        (if objsToCopy
          (progn
            (setq copyRes (vl-catch-all-apply
                            'vlax-invoke
                            (list doc 'CopyObjects objsToCopy targetDef)))

            (if (vl-catch-all-error-p copyRes)
              (princ (strcat "\n  ✘ 複製失敗：" (vl-catch-all-error-message copyRes)))
              (progn
                (setq pt1 (vlax-3d-point 0.0 0.0 0.0)
                      pt2 (vlax-3d-point dX dY dZ))

                ;; 移動 + 恢復顏色（包含屬性）
                (mapcar
                  (function
                    (lambda (newObj)
                      (if (or (/= dX 0.0) (/= dY 0.0) (/= dZ 0.0))
                        (vl-catch-all-apply 'vla-Move (list newObj pt1 pt2))
                      )
                      (if (not (vl-catch-all-error-p
                                 (setq lay (vla-get-Layer newObj))))
                        (if (setq mappedCol (cdr (assoc lay layColorMap)))
                          (vl-catch-all-apply 'vla-put-Color (list newObj mappedCol))
                        )
                      )
                    )
                  )
                  copyRes
                )

                ;; 關鍵：自動同步屬性到所有插入實例
                (vl-cmdf "_.attsync" "_n" targetName)

                (princ (strcat "\n  ✔ 完成 (" (itoa (length geometryToCopy)) " 幾何 + "
                               (itoa (length attDefsToCopy)) " 屬性)，已繼承顏色並同步屬性"))
              )
            )
          )
          (princ "\n  ✘ 沒有可複製的物件")
        )
      )
    )
    (setq i (1+ i))
  )

  (setvar 'cmdecho oldEcho)
  (vla-Regen doc acActiveViewport)
  (vla-EndUndoMark doc)

  (princ "\n\n=============================")
  (princ "\n全部同步完成！（包含屬性定義 + ATTSYNC）")
  (princ "\n=============================\n")
  (princ)
)

(defun c:SFM () (c:SyncNow))

(princ "\nSyncBlock v12-AttSync 載入成功。輸入 SyncNow 或 SFM 開始使用。")
(princ)