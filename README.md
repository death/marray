# MARRAY

Memory mapped files as Lisp arrays.

## [Macro] with-file-mapping (array filename) &body forms

Evaluate `FORMS` with `ARRAY` bound to the contents of the file
designated by `FILENAME`.  The contents are represented as an array of
type `(SIMPLE-ARRAY (UNSIGNED-BYTE 8))`.

Signals an error if the file cannot be mapped.

The following limitations apply:

- The file is mapped from beginning to end;
- The mapping is private;
- The mapping is read-only (i.e. vector elements should not be modified);
- The array is valid only for the dynamic extent of the evaluation of the forms.

## Example

```lisp
CL-USER> (time
          (loop repeat 100000
                do (ironclad:digest-file :sha1 "/etc/passwd")))
Evaluation took:
  3.361 seconds of real time
  3.357516 seconds of total run time (2.628728 user, 0.728788 system)
  [ Run times consist of 0.170 seconds GC time, and 3.188 seconds non-GC time. ]
  99.91% CPU
  42 lambdas converted
  10,730,647,992 processor cycles
  13,539,966,368 bytes consed

NIL
CL-USER> (time
          (loop repeat 100000
                do (marray:with-file-mapping (array "/etc/passwd")
                     (ironclad:digest-sequence :sha1 array))))
Evaluation took:
  2.757 seconds of real time
  2.746022 seconds of total run time (1.941735 user, 0.804287 system)
  [ Run times consist of 0.005 seconds GC time, and 2.742 seconds non-GC time. ]
  99.60% CPU
  2,000,008 forms interpreted
  64 lambdas converted
  8,799,909,724 processor cycles
  733,703,072 bytes consed

NIL
```

## License

MIT
