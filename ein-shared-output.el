;;; ein-shared-output.el --- Output buffer for ein-connect.el

;; Copyright (C) 2012- Takafumi Arakaki

;; Author: Takafumi Arakaki

;; This file is NOT part of GNU Emacs.

;; ein-shared-output.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; ein-shared-output.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with ein-shared-output.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; When executing code from outside of notebook, some place for output
;; is needed.  This module buffer containing one special cell for that
;; purpose.

;;; Code:

(eval-when-compile (require 'cl))
(require 'eieio)

(require 'ein-cell)

(defclass ein:shared-output-cell (ein:codecell)
  ((cell-type :initarg :cell-type :initform "shared-output")
   ;; (element-names :initform (:prompt :output :footer))
   )
  "A singleton cell to show output from non-notebook buffers.")

(defclass ein:$shared-output ()
  ((cell :initarg :cell :type ein:shared-output-cell)
   (ewoc :initarg :ewoc :type ewoc)))

(defvar ein:@shared-output nil
  "Hold an instance of `ein:$shared-output'.")

(defconst ein:shared-output-buffer-name "*ein:shared-output*")

(defmethod ein:cell-execute ((cell ein:shared-output-cell) kernel code)
  (ein:cell-execute-internal cell kernel code))

(defmethod ein:cell--handle-output ((cell ein:shared-output-cell)
                                    msg-type content)
  (ein:log 'info "Got output '%s' in the shared buffer." msg-type)
  (call-next-method))

(defun ein:shared-output-get-buffer ()
  "Get the shared output buffer."
  (get-buffer-create ein:shared-output-buffer-name))

(defun ein:shared-output-get-or-create ()
  (if ein:@shared-output
      ein:@shared-output
    (with-current-buffer (ein:shared-output-get-buffer)
      ;; FIXME: This is a duplication of `ein:notebook-from-json'.
      ;;        Must be merged.
      (let* ((inhibit-read-only t)
             ;; Enable nonsep for ewoc object (the last argument is non-nil).
             ;; This is for putting read-only text properties to the newlines.
             ;; FIXME: Do not depend on `ein:notebook-pp'!
             (ewoc (ewoc-create 'ein:notebook-pp
                                (ein:propertize-read-only "\n")
                                nil t))
             (cell (ein:shared-output-cell "SharedOutputCell"
                                           :ewoc ewoc)))
        (erase-buffer)
        (setq ein:@shared-output
              (ein:$shared-output "SharedOutput" :ewoc ewoc :cell cell))
        (ein:cell-enter-last cell))
      ein:@shared-output)))

(defun ein:shared-output-get-cell ()
  "Get the singleton shared output cell.
Create a cell if the buffer has none."
  (oref (ein:shared-output-get-or-create) :cell))

(defun ein:shared-output-pop-to-buffer ()
  (interactive)
  (ein:shared-output-get-or-create)
  (pop-to-buffer (ein:shared-output-get-buffer)))

(provide 'ein-shared-output)

;;; ein-shared-output.el ends here