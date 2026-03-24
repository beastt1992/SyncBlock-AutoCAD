;;; ============================================================
;;; SyncBlock.lsp v22 (The Consensus Voting Registration)
;;; Command: SyncNow / SFM
;;; ============================================================
(vl-load-com)

(defun get-obj-center (obj / ll ur)
  (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
    (progn
      (setq ll (vlax-safearray->list ll)
            ur (vlax-safearray->list ur))
      (list (/ (+ (car ll) (car ur)) 2.0)
            (/ (+ (cadr ll) (cadr ur)) 2.0))
    )
    nil
  )
)

(defun get-consensus-offset (masterDef targetDef layerList /
                             tCenters mCenters voteList maxVote bestDx bestDy
                             cPt mPt dx dy key existing objName pt)
  (setq tCenters '() mCenters '())

  (vlax-for obj targetDef
    (setq objName (vla-get-ObjectName obj))
    (if (and (member (vla-get-Layer obj) layerList)
             (/= objName "AcDbHatch")
             (/= objName "AcDbAttributeDefinition")
             (/= objName "AcDbText")
             (/= objName "AcDbMText")
             (not (vl-string-search "Dimension" objName)))
      (if (setq pt (get-obj-center obj))
        (setq tCenters (cons pt tCenters))
      )
    )
  )

  (vlax-for obj masterDef
    (setq objName (vla-get-ObjectName obj))
    (if (and (member (vla-get-Layer obj) layerList)
             (/= objName "AcDbHatch")
             (/= objName "AcDbAttributeDefinition")
             (/= objName "AcDbText")
             (/= objName "AcDbMText")
             (not (vl-string-search "Dimension" objName)))
      (if (setq pt (get-obj-center obj))
        (setq mCenters (cons pt mCenters))
      )
    )
  )

  (setq voteList '())
  (if (and tCenters mCenters)
    (foreach tPt tCenters
      (foreach mPt mCenters
        (setq dx (- (car tPt) (car mPt)))
        (setq dy (- (cadr tPt) (cadr mPt)))
        (setq key (strcat (rtos dx 2 1) "," (rtos dy 2 1)))
        (setq existing (assoc key voteList))
        (if existing
          (setq voteList (subst (list key (1+ (cadr existing)) dx dy) existing voteList))
          (setq voteList (cons (list key 1 dx dy) voteList))
        )
      )
    )
  )

  (setq maxVote 0 bestDx nil bestDy nil)
  (foreach item voteList
    (if (> (cadr item) maxVote)
      (setq maxVote (cadr item) bestDx (caddr item) bestDy (cadddr item))
    )
  )

  (if (> maxVote 0)
    (list bestDx bestDy 0.0)
    nil
  )
)

(defun c:SyncNow ( / acadObj doc blocks
                    masterEnt masterVla masterName masterDef
                    targetSS i targetEnt targetVla targetName targetDef
                    layerList lay targetObjs obj geometryToCopy
                    consensusOffset dX dY dZ pt1 pt2 copyRes successCount)

  (setq acadObj (vlax-get-acad-object))
  (setq doc     (vla-get-ActiveDocument acadObj))
  (setq blocks  (vla-get-Blocks doc))

  (if (not (setq masterEnt (car (entsel "\nSelect Master Block A (v22 - Voting Sync): "))))
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
    (setq targetEnt  (ssname targetSS i))
    (setq targetVla  (vlax-ename->vla-object targetEnt))
    (setq targetName (vla-get-EffectiveName targetVla))

    (if (= targetName masterName)
      (princ (strcat "\nSkip master: " targetName))
      (progn
        (princ (strcat "\nProcessing: " targetName))
        (setq targetDef (vla-Item blocks targetName))

        (setq layerList '() targetObjs '())
        (vlax-for obj targetDef
          (setq lay (vla-get-Layer obj))
          (if (not (member lay layerList))
            (setq layerList (cons lay layerList))
          )
        )

        (setq geometryToCopy '())
        (vlax-for obj masterDef
          (if (and (member (vla-get-Layer obj) layerList)
                   (/= (vla-get-ObjectName obj) "AcDbHatch"))
            (setq geometryToCopy (cons obj geometryToCopy))
          )
        )

        (setq consensusOffset (get-consensus-offset masterDef targetDef layerList))

        (setq dX 0.0 dY 0.0 dZ 0.0)
        (if consensusOffset
          (progn
            (setq dX (car consensusOffset) dY (cadr consensusOffset) dZ (caddr consensusOffset))
            (princ (strcat "\n  Consensus Offset: (" (rtos dX 2 1) ", " (rtos dY 2 1) ")"))
          )
          (princ "\n  [Warning] Cannot align. No consensus found.")
        )

        (vlax-for obj targetDef
          (vl-catch-all-apply 'vla-Delete (list obj))
        )

        (if geometryToCopy
          (progn
            (setq copyRes (vl-catch-all-apply 'vlax-invoke (list doc 'CopyObjects geometryToCopy targetDef)))
            (if (not (vl-catch-all-error-p copyRes))
              (progn
                (setq pt1 (vlax-3d-point 0.0 0.0 0.0))
                (setq pt2 (vlax-3d-point dX dY dZ))
                (setq successCount 0)
                (foreach newObj copyRes
                  (if (or (/= dX 0.0) (/= dY 0.0) (/= dZ 0.0))
                    (vl-catch-all-apply 'vla-Move (list newObj pt1 pt2))
                  )
                  (setq successCount (1+ successCount))
                )
                (princ (strcat "\n  Done: " (itoa successCount) " objects synced perfectly."))
              )
              (princ "\n  Copy Failed.")
            )
          )
        )
      )
    )
    (setq i (1+ i))
  )

  (vla-Regen doc acActiveViewport)
  (vla-EndUndoMark doc)
  (princ "\n=============================")
  (princ "\nSync complete (v22 - Voting)!")
  (princ "\n=============================\n")
  (princ)
)

(defun c:SFM () (c:SyncNow))
(princ "\nSyncBlock v22 loaded. Type SyncNow or SFM to run.")
(princ)