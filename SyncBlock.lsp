;;; SyncBlock.lsp v18
;;; 基於 v12 邏輯，修正複製方式為逐一處理，跳過 Hatch
;;; 指令：SyncNow 或 SFM
(vl-load-com)

(defun get-bbox-min (objList / minX minY minZ ll ur)
  (setq minX 1e99 minY 1e99 minZ 0.0)
  (foreach obj objList
    (if (and (/= (vla-get-ObjectName obj) "AcDbAttributeDefinition")
             (/= (vla-get-ObjectName obj) "AcDbHatch")
             (not (vl-catch-all-error-p
                    (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur)))))
      (progn
        (setq ll (vlax-safearray->list ll))
        (setq minX (min minX (car ll)))
        (setq minY (min minY (cadr ll)))
      )
    )
  )
  (if (= minX 1e99) nil (list minX minY minZ))
)

(defun copy-obj (doc obj targetDef pt1 pt2 / res)
  (setq res (vl-catch-all-apply
              'vlax-invoke
              (list doc 'CopyObjects (list obj) targetDef)))
  (if (not (vl-catch-all-error-p res))
    (progn
      (if pt2
        (foreach o res
          (vl-catch-all-apply 'vla-Move (list o pt1 pt2))
        )
      )
      T
    )
    nil
  )
)

(defun c:SyncNow ( / acadObj doc blocks
                    masterEnt masterVla masterName masterDef
                    targetSS i targetEnt targetVla targetName targetDef
                    layerList targetObjs targetGeometry obj lay
                    geometryToCopy minPtA minPtB dX dY dZ
                    pt1 pt2 successCount failCount skipCount)

  (setq acadObj (vlax-get-acad-object))
  (setq doc     (vla-get-ActiveDocument acadObj))
  (setq blocks  (vla-get-Blocks doc))

  ; ── 1. 點選 Block A ──────────────────────────────
  (if (not (setq masterEnt (car (entsel "\n【SyncBlock】點選主底圖 Block A: "))))
    (progn (princ "\n取消。") (exit))
  )
  (setq masterVla (vlax-ename->vla-object masterEnt))
  (if (/= (vla-get-ObjectName masterVla) "AcDbBlockReference")
    (progn (princ "\n不是 Block。") (exit))
  )
  (setq masterName (vla-get-EffectiveName masterVla))
  (setq masterDef  (vla-Item blocks masterName))
  (princ (strcat "\n✔ 主底圖：" masterName))

  ; ── 2. 框選目標 ──────────────────────────────────
  (princ "\n\n框選所有目標 Block: ")
  (if (not (setq targetSS (ssget '((0 . "INSERT")))))
    (progn (princ "\n取消。") (exit))
  )

  (vla-StartUndoMark doc)
  (setq i 0)

  (while (< i (sslength targetSS))
    (setq targetEnt  (ssname targetSS i))
    (setq targetVla  (vlax-ename->vla-object targetEnt))
    (setq targetName (vla-get-EffectiveName targetVla))

    (if (= targetName masterName)
      (princ (strcat "\n跳過：" targetName))
      (progn
        (princ (strcat "\n\n處理：" targetName))
        (setq targetDef (vla-Item blocks targetName))

        ; 讀取目標圖層和幾何物件
        (setq layerList '() targetObjs '() targetGeometry '())
        (vlax-for obj targetDef
          (setq lay (vla-get-Layer obj))
          (if (not (member lay layerList))
            (setq layerList (cons lay layerList))
          )
          (setq targetObjs (cons obj targetObjs))
          (if (and (/= (vla-get-ObjectName obj) "AcDbAttributeDefinition")
                   (/= (vla-get-ObjectName obj) "AcDbHatch"))
            (setq targetGeometry (cons obj targetGeometry))
          )
        )
        (princ (strcat "\n  " (itoa (length layerList)) " 個圖層"))

        ; 計算目標 BBox
        (setq minPtB (get-bbox-min targetObjs))

        ; 收集 Master 符合圖層的幾何物件（跳過 Hatch）
        (setq geometryToCopy '())
        (vlax-for obj masterDef
          (if (and (member (vla-get-Layer obj) layerList)
                   (/= (vla-get-ObjectName obj) "AcDbHatch"))
            (setq geometryToCopy (cons obj geometryToCopy))
          )
        )
        (princ (strcat "，" (itoa (length geometryToCopy)) " 個物件"))

        ; 計算位移
        (setq minPtA (get-bbox-min geometryToCopy))
        (setq dX 0.0 dY 0.0 dZ 0.0)
        (if (and minPtA minPtB)
          (progn
            (setq dX (- (car minPtB)   (car minPtA)))
            (setq dY (- (cadr minPtB)  (cadr minPtA)))
            (setq dZ (- (caddr minPtB) (caddr minPtA)))
          )
        )
        (princ (strcat "\n  位移：(" (rtos dX 2 1) ", " (rtos dY 2 1) ")"))

        ; 清空目標 Block
        (vlax-for obj targetDef
          (vl-catch-all-apply 'vla-Delete (list obj))
        )

        ; 設定移動點
        (setq pt1 (vlax-3d-point 0.0 0.0 0.0))
        (if (or (/= dX 0.0) (/= dY 0.0) (/= dZ 0.0))
          (setq pt2 (vlax-3d-point dX dY dZ))
          (setq pt2 nil)
        )

        ; 逐一複製
        (setq successCount 0 failCount 0)
        (foreach obj geometryToCopy
          (if (copy-obj doc obj targetDef pt1 pt2)
            (setq successCount (1+ successCount))
            (setq failCount    (1+ failCount))
          )
        )

        (princ (strcat "\n  ✔ " (itoa successCount) " 個完成（Hatch 略過）"))
        (if (> failCount 0)
          (princ (strcat "，⚠ " (itoa failCount) " 個失敗"))
        )
      )
    )
    (setq i (1+ i))
  )

  (vla-Regen doc 2)
  (vla-EndUndoMark doc)
  (princ "\n\n=============================")
  (princ "\n全部同步完成！")
  (princ "\n=============================\n")
  (princ)
)

(defun c:SFM () (c:SyncNow))
(princ "\nSyncBlock v18 載入成功。輸入 SyncNow 或 SFM 開始使用。")
(princ)
