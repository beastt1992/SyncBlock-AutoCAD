;;; ============================================================
;;; SyncBlock.lsp v30
;;; Speed Upgrade: Unified loops. Dropped COM iterations from 20k -> 6k.
;;; Command: SyncNow / SFM
;;; ============================================================
(vl-load-com)

(defun get-obj-center (obj / ll ur)
  (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
    (progn
      (setq ll (vlax-safearray->list ll) ur (vlax-safearray->list ur))
      (list (/ (+ (car ll) (car ur)) 2.0) (/ (+ (cadr ll) (cadr ur)) 2.0))
    )
    nil
  )
)

(defun c:SyncNow ( / acadObj doc blocks masterEnt masterVla masterName masterDef
                    targetSS i targetEnt targetVla targetName targetDef
                    layerList layColorMap tCenters tCounts tMin objsToDelete
                    mCenters mCounts mMin geometryToCopy hatchCount
                    obj objName lay pt curCountItem curCount ll ur
                    voteList maxVote bestDx bestDy dx dy key existing
                    finalOffset dX dY dZ pt1 pt2 copyRes successCount objLay mappedCol)

  (setq acadObj (vlax-get-acad-object)
        doc     (vla-get-ActiveDocument acadObj)
        blocks  (vla-get-Blocks doc))

  (if (not (setq masterEnt (car (entsel "\nSelect Master Block A: "))))
    (progn (princ "\nCancelled.") (exit))
  )
  (setq masterVla (vlax-ename->vla-object masterEnt))
  (if (/= (vla-get-ObjectName masterVla) "AcDbBlockReference")
    (progn (princ "\nNot a Block.") (exit))
  )
  (setq masterName (vla-get-EffectiveName masterVla))
  (setq masterDef  (vla-Item blocks masterName))
  (princ (strcat "\nMaster: " masterName))

  (princ "\nWindow-select target Blocks: ")
  (if (not (setq targetSS (ssget '((0 . "INSERT")))))
    (progn (princ "\nCancelled.") (exit))
  )

  (vla-StartUndoMark doc)
  (setq i 0)

  (while (< i (sslength targetSS))
    (setq targetEnt  (ssname targetSS i)
          targetVla  (vlax-ename->vla-object targetEnt)
          targetName (vla-get-EffectiveName targetVla))

    (if (= targetName masterName)
      (princ (strcat "\nSkip master: " targetName))
      (progn
        (princ (strcat "\nProcessing: " targetName))
        (setq targetDef (vla-Item blocks targetName))

        ;; ----------------------------------------------------
        ;; PASS 1: TARGET DEF (Gather layers, colors, centers, BBox)
        ;; ----------------------------------------------------
        (setq layerList '() layColorMap '() tCenters '() tCounts '() objsToDelete '() tMin (list 1e99 1e99))
        (vlax-for obj targetDef
          (setq objsToDelete (cons obj objsToDelete))
          (setq lay (vla-get-Layer obj))
          (setq objName (vla-get-ObjectName obj))

          ;; Layers & Colors
          (if (not (member lay layerList)) (setq layerList (cons lay layerList)))
          (if (and (not (assoc lay layColorMap)) (not (vl-catch-all-error-p (setq col (vl-catch-all-apply 'vla-get-Color (list obj))))))
            (setq layColorMap (cons (cons lay col) layColorMap))
          )

          ;; Geometry check for Center & BBox
          (if (and (/= objName "AcDbHatch") (/= objName "AcDbAttributeDefinition")
                   (/= objName "AcDbText") (/= objName "AcDbMText")
                   (not (vl-string-search "Dimension" objName)))
            (progn
              ;; BBox Fallback calc
              (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
                (setq tMin (list (min (car tMin) (car (vlax-safearray->list ll))) (min (cadr tMin) (cadr (vlax-safearray->list ll)))))
              )
              ;; Centers calc
              (setq curCountItem (assoc lay tCounts))
              (setq curCount (if curCountItem (cdr curCountItem) 0))
              (if (< curCount 12)
                (if (setq pt (get-obj-center obj))
                  (progn
                    (setq tCenters (cons pt tCenters))
                    (setq tCounts (if curCountItem (subst (cons lay (1+ curCount)) curCountItem tCounts) (cons (cons lay 1) tCounts)))
                  )
                )
              )
            )
          )
        )

        ;; ----------------------------------------------------
        ;; PASS 2: MASTER DEF (Gather copy items, centers, BBox)
        ;; ----------------------------------------------------
        (setq geometryToCopy '() mCenters '() mCounts '() hatchCount 0 mMin (list 1e99 1e99))
        (vlax-for obj masterDef
          (setq lay (vla-get-Layer obj))
          (if (member lay layerList)
            (progn
              (setq objName (vla-get-ObjectName obj))
              (if (= objName "AcDbHatch")
                (setq hatchCount (1+ hatchCount))
                (progn
                  (setq geometryToCopy (cons obj geometryToCopy))
                  ;; Geometry check for Center & BBox
                  (if (and (/= objName "AcDbAttributeDefinition")
                           (/= objName "AcDbText") (/= objName "AcDbMText")
                           (not (vl-string-search "Dimension" objName)))
                    (progn
                      ;; BBox Fallback calc
                      (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
                        (setq mMin (list (min (car mMin) (car (vlax-safearray->list ll))) (min (cadr mMin) (cadr (vlax-safearray->list ll)))))
                      )
                      ;; Centers calc
                      (setq curCountItem (assoc lay mCounts))
                      (setq curCount (if curCountItem (cdr curCountItem) 0))
                      (if (< curCount 12)
                        (if (setq pt (get-obj-center obj))
                          (progn
                            (setq mCenters (cons pt mCenters))
                            (setq mCounts (if curCountItem (subst (cons lay (1+ curCount)) curCountItem mCounts) (cons (cons lay 1) mCounts)))
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
        (princ (strcat "\n  Objects: " (itoa (length geometryToCopy)) (if (> hatchCount 0) (strcat " (+" (itoa hatchCount) " Hatch)") "")))

        ;; ----------------------------------------------------
        ;; PASS 3: VOTING & CALCULATE OFFSET
        ;; ----------------------------------------------------
        (setq maxVote 0 finalOffset nil)
        (if (and tCenters mCenters)
          (progn
            (setq voteList '())
            (foreach tPt tCenters
              (foreach mPt mCenters
                (setq dx (- (car tPt) (car mPt)) dy (- (cadr tPt) (cadr mPt)))
                (setq key (strcat (rtos dx 2 1) "," (rtos dy 2 1)))
                (setq existing (assoc key voteList))
                (if existing
                  (setq voteList (subst (list key (1+ (cadr existing)) dx dy) existing voteList))
                  (setq voteList (cons (list key 1 dx dy) voteList))
                )
              )
            )
            (foreach item voteList
              (if (> (cadr item) maxVote)
                (setq maxVote (cadr item) bestDx (caddr item) bestDy (cadddr item))
              )
            )
          )
        )

        (if (>= maxVote 3)
          (progn
            ; voting success - silent
            (setq finalOffset (list bestDx bestDy 0.0))
          )
          (progn
            (princ "\n  [BBox fallback]")
            (if (and (/= (car mMin) 1e99) (/= (car tMin) 1e99))
              (setq finalOffset (list (- (car tMin) (car mMin)) (- (cadr tMin) (cadr mMin)) 0.0))
            )
          )
        )

        (setq dX 0.0 dY 0.0 dZ 0.0)
        (if finalOffset
          (progn
            (setq dX (car finalOffset) dY (cadr finalOffset) dZ (caddr finalOffset))
            ; offset silent
          )
          (princ "\n  [Warning] No alignment found")
        )

        ;; ----------------------------------------------------
        ;; PASS 4: APPLY CHANGES (Delete, Copy, Transform)
        ;; ----------------------------------------------------
        ;; Delete old objects
        (foreach obj objsToDelete
          (vl-catch-all-apply 'vla-Delete (list obj))
        )

        ;; Bulk Copy & Transform
        (if geometryToCopy
          (progn
            (setq pt1 (vlax-3d-point 0.0 0.0 0.0))
            (setq pt2 (if (or (/= dX 0.0) (/= dY 0.0) (/= dZ 0.0)) (vlax-3d-point dX dY dZ) nil))
            
            (setq copyRes (vl-catch-all-apply 'vlax-invoke (list doc 'CopyObjects geometryToCopy targetDef)))
            (if (not (vl-catch-all-error-p copyRes))
              (progn
                (setq successCount 0)
                (foreach newObj copyRes
                  (if pt2 (vl-catch-all-apply 'vla-Move (list newObj pt1 pt2)))
                  (if (not (vl-catch-all-error-p (setq objLay (vl-catch-all-apply 'vla-get-Layer (list newObj)))))
                    (if (setq mappedCol (cdr (assoc objLay layColorMap)))
                      (vl-catch-all-apply 'vla-put-Color (list newObj mappedCol))
                    )
                  )
                  (setq successCount (1+ successCount))
                )
                (princ (strcat "\n  Done: " (itoa successCount) " objects synced."))
              )
              (princ "\n  [Error] Copy failed. Press Ctrl+Z to undo.")
            )
          )
        )
      )
    )
    (setq i (1+ i))
  )

  (vla-Regen doc 2)
  (vla-EndUndoMark doc)
  (princ "\n=============================")
  (princ "\nSync complete! (v30)")
  (princ "\n=============================\n")
  (princ)
)

(defun c:SFM () (c:SyncNow))
(princ "\nSyncBlock v30 loaded. Type SyncNow or SFM to run.")
(princ)