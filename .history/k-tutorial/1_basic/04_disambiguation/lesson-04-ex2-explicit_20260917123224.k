// Exercise 2 (explicit priority/associativity declarations)
module LESSON-04-EX2-EXPLICIT

  syntax Int ::= r"[0-9]+" [token]

  syntax Exp ::= Int [group(atom)]
               | "(" Exp ")" [group(atom), bracket]
               | "-" Exp [group(neg)]
               | Exp "*" Exp [group(mul)]
               | Exp "/" Exp [group(mul)]
               | Exp "+" Exp [group(add)]
               | Exp "-" Exp [group(add)]

  syntax priority atom > neg > mul > add
  syntax left mul
  syntax left add

endmodule
