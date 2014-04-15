(in-package :coleslaw)

;;;; The Document Protocol

;; Data Storage

(defvar *site* (make-hash-table :test #'equal)
  "An in-memory database to hold all site documents, keyed on page-url.")

;; Class Methods

(defun find-all (doc-type)
  "Return a list of all instances of a given DOC-TYPE."
  (loop for val being the hash-values in *site*
     when (typep val doc-type) collect val))

(defun purge-all (doc-type)
  "Remove all instances of DOC-TYPE from memory."
  (dolist (obj (find-all doc-type))
    (remhash (page-url obj) *site*)))

(defgeneric publish (doc-type)
  (:documentation "Write pages to disk for all documents of the given DOC-TYPE."))

(defgeneric discover (doc-type)
  (:documentation "Load all documents of the given DOC-TYPE into memory.")
  (:method (doc-type)
    (purge-all doc-type)
    (let* ((class-name (class-name doc-type))
           (file-type (string-downcase (symbol-name class-name))))
      (do-files (file (repo *config*) file-type)
        (let ((obj (construct class-name (read-content file))))
          (if (gethash (page-url obj) *site*)
              (error "There is already existing content with the url ~a."
                     (page-url obj))
              (setf (gethash (page-url obj) *site*) obj)))))))

;; Instance Methods

(defgeneric page-url (document)
  (:documentation "The url to the document, without the domain."))

(defmethod page-url :around ((document t))
  (let ((result (call-next-method)))
    (if (pathname-type result)
        result
        (make-pathname :type "html" :defaults result))))

(defgeneric render (document &key &allow-other-keys)
  (:documentation "Render the given DOCUMENT to HTML."))