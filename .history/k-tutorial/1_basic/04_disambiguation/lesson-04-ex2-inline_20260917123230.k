// Exercise 2 (inline priority blocks, equivalent to lesson-04-ex2-explicit.k)
module LESSON-04-EX2-INLINE

  syntax Int ::= r"[0-9]+" [token]

  syntax Exp ::= Int
               | "(" Exp ")" [bracket]
               > "-" Exp
               > left:
                 Exp "*" Exp
               | Exp "/" Exp
               > left:
                 Exp "+" Exp
               | Exp "-" Exp

endmodule
