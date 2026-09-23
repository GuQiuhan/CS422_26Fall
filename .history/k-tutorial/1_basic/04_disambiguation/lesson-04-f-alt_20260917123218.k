// Exercise 1: move `avoid` to the other production so that the `else`
// attaches to the outer (first) `if` instead of the inner one.
module LESSON-04-F-ALT

  syntax Exp ::= "true" | "false"
  syntax Stmt ::= "if" "(" Exp ")" Stmt [avoid]
                | "if" "(" Exp ")" Stmt "else" Stmt
                | "{" "}"

endmodule
