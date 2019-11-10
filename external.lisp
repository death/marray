;;;; +----------------------------------------------------------------+
;;;; | MARRAY                                                         |
;;;; +----------------------------------------------------------------+

;;;; Implementation of external interface

(in-package #:marray)

(unless (fboundp 'call-with-file-mapping)
  (error "MARRAY is not implemented on this platform; patches welcome!"))

(defmacro with-file-mapping ((array filename) &body forms)
  "Evaluate FORMS with ARRAY bound to the contents of the file
designated by FILENAME.  The contents are represented as an array of
type (SIMPLE-ARRAY (UNSIGNED-BYTE 8)).

Signals an error if the file cannot be mapped.

The following limitations apply:

- The file is mapped from beginning to end;
- The mapping is private;
- The mapping is read-only (i.e. vector elements should not be modified);
- The array is valid only for the dynamic extent of the evaluation of the forms."
  `(call-with-file-mapping ,filename
                           (lambda (,array)
                             (declare (dynamic-extent ,array))
                             ,@forms)))
