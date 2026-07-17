(do
  ; load the standard library shipped with aria (provides dostring)
  (eval (parse (loads "lib.lsp") "lib.lsp") global)

  ; let / while
  (let (i 0 acc 0)
    (while (< i 10)
      (= acc (+ acc i))
      (= i (+ i 1)))
    (print acc))                 ; 45

  ; and / or / if chains
  (print (and 1 2 3))            ; 3
  (print (or nil nil 7))         ; 7
  (print (if nil 'a
             t   'b
             'c))                ; b

  ; fn + apply + eval
  (= add (fn (a b) (+ a b)))
  (print (apply add '(20 22)))   ; 42
  (print (eval '(+ 1 2)))        ; 3

  ; macro expansion
  (= twice (macro (x) (list 'do x x)))
  (= n 0)
  (twice (= n (+ n 1)))
  (print n)                      ; 2

  ; pcall error handling: error value is reported, execution continues
  (print (pcall (fn () (error "boom"))
                (fn (err tr) (string "caught:" err))))  ; caught:boom
  (print (pcall (fn () 42)
                (fn (err tr) 'unreached)))              ; 42

  ; dostring
  (print (dostring "(+ 40 2)")))  ; 42
