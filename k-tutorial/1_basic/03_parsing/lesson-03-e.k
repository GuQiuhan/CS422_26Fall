module LESSON-03-E

  syntax Int ::= r"[0-9]+" [token]

  syntax Exp ::= Int
               | "(" Exp ")" [bracket]
               | "-" Exp
               | Exp "+" Exp
               | Exp "-" Exp
               | Exp "*" Exp
               | Exp "/" Exp

endmodule
