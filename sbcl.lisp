;;;; +----------------------------------------------------------------+
;;;; | MARRAY                                                         |
;;;; +----------------------------------------------------------------+

;;;; SBCL-specific implementation

(in-package #:marray)

(defvar *page-size*
  (sb-posix:getpagesize))

(defconstant map-noreserve #x4000)
(defconstant map-uninitialized #x4000000)

(defun reserve-pages (n)
  "Reserve N pages of memory and return a pointer to the first."
  (sb-posix:mmap nil
                 (* n *page-size*)
                 (logior sb-posix:prot-read
                         sb-posix:prot-write)
                 (logior sb-posix:map-private
                         sb-posix:map-anon
                         map-noreserve
                         map-uninitialized)
                 -1
                 0))

(defun place-array (pre size)
  "Return an octet vector of SIZE elements residing in the successor
page of PRE.  The last bytes in the PRE page are used for the array's
header."
  (let* ((contents (sb-sys:sap+ pre *page-size*))
         (header-ptr (sb-sys:sap+ contents
                                  (- (* sb-vm:vector-data-offset
                                        sb-vm:n-word-bytes))))
         (tagged-ptr (sb-sys:sap+ header-ptr
                                  sb-vm:other-pointer-lowtag)))
    (setf (sb-sys:sap-ref-word header-ptr 0)
          sb-vm:simple-array-unsigned-byte-8-widetag)
    (setf (sb-sys:sap-ref-word header-ptr
                               (* sb-vm:vector-length-slot
                                  sb-vm:n-word-bytes))
          (sb-vm:fixnumize size))
    (sb-kernel:%make-lisp-obj (sb-sys:sap-int tagged-ptr))))

(defun mmap-fd (fd)
  "Map file contents into memory and return the following values:

- The octet vector with the file contents;
- The pointer to the page containing the array header;
- The number of pages allocated."
  (let* ((size (sb-posix:stat-size (sb-posix:fstat fd)))
         (n (1+ (ceiling size *page-size*)))
         (pre (reserve-pages n)))
    (when (plusp size)
      (sb-posix:mmap (sb-sys:sap+ pre *page-size*)
                     size
                     sb-posix:prot-read
                     (logior sb-posix:map-private
                             sb-posix:map-fixed)
                     fd
                     0))
    (sb-posix:mmap pre
                   *page-size*
                   (logior sb-posix:prot-read
                           sb-posix:prot-write)
                   (logior sb-posix:map-private
                           sb-posix:map-fixed
                           sb-posix:map-anon)
                   -1
                   0)
    (values (place-array pre size)
            pre
            n)))

(defun unmap (pre n)
  "Unmap N pages starting at PRE."
  (sb-posix:munmap pre (* n *page-size*)))

(defun call-with-file-mapping (filename function)
  "Call FUNCTION with an octet vector with elements representing the
contents of the file designated by FILENAME."
  (let ((fd (sb-posix:open filename sb-posix:o-rdonly)))
    (unwind-protect
         (sb-sys:without-interrupts
           (multiple-value-bind (array pre n)
               (mmap-fd fd)
             (unwind-protect
                  (sb-sys:with-local-interrupts
                    (sb-posix:close fd)
                    (setq fd -1)
                    (funcall function array))
               (unmap pre n))))
      (unless (= fd -1)
        (sb-posix:close fd)))))
