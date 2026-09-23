module LESSON-09-B
  imports BOOL

  syntax Stmt ::= "{" Stmt "}" | "{" "}"
                > right:
                  Stmt Stmt
                | "if" "(" Bool ")" Stmt
                | "if" "(" Bool ")" Stmt "else" Stmt [avoid]
endmodule
