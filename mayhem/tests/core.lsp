(do
  ; load the standard library shipped with aria
  (eval (parse (loads "lib.lsp") "lib.lsp") global)

  ; arithmetic + comparison
  (print (+ 1 2 3 4 5))          ; 15
  (print (- 100 42))             ; 58
  (print (* 6 7))                ; 42
  (print (/ 84 2))               ; 42
  (print (< 1 2))                ; t
  (print (>= 2 3))               ; nil
  (print (is 3 3))               ; t

  ; strings
  (print (string "foo" "bar"))   ; foobar
  (print (substr "hello world" 6))  ; world
  (print (upper "abc"))          ; ABC
  (print (lower "XYZ"))          ; xyz
  (print (strlen "aria"))        ; 4

  ; pairs / lists
  (print (car '(1 2 3)))         ; 1
  (print (cdr '(1 2 3)))         ; (2 3)
  (print (nth 2 '(a b c d)))     ; c   (lib.lsp)
  (print (cons 1 '(2 3)))        ; (1 2 3)
  (print (list 1 "two" 'three))  ; (1 "two" three)
  (print (type '(1)))            ; pair
  (print (type "s"))             ; string
  (print (type 1))               ; number

  ; lib.lsp higher-order functions
  (print (map (fn (x) (* x x)) '(1 2 3 4)))   ; (1 4 9 16)
  (print (filter (fn (x) (< x 3)) '(1 2 3 4))) ; (1 2)
  (print (reduce + '(1 2 3 4) 0))              ; 10
  (print (reverse '(1 2 3)))                   ; (3 2 1)
  (print (join (split "a,b,c" ",") "-"))       ; a-b-c
  (print (len '(a b c)))                       ; 3

  ; () parses as nil
  (print ()))
