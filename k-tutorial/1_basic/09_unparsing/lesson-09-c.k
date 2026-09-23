module LESSON-09-C
  imports BOOL

  syntax Stmt ::= "{" Stmt "}" [format(%1%i%n%2%d%n%3)] | "{" "}" [format(%1%2)]
                > right:
                  Stmt Stmt [format(%1%n%2)]
                | "if" "(" Bool ")" Stmt [format(%1 %2%3%4 %5)]
                | "if" "(" Bool ")" Stmt "else" Stmt [avoid, format(%1 %2%3%4 %5 %6 %7)]
endmodule
