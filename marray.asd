;;;; +----------------------------------------------------------------+
;;;; | MARRAY                                                         |
;;;; +----------------------------------------------------------------+

;;;; System definition

;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: CL-USER; Base: 10 -*-

(asdf:defsystem #:marray
  :description "Memory mapped files as Lisp arrays."
  :author "death <github.com/death>"
  :license "MIT"
  :serial t
  :components
  ((:file "packages")
   #+sbcl (:file "sbcl")
   (:file "external")))
