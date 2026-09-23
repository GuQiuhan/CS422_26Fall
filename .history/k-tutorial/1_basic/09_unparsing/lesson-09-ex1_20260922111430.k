module LESSON-09-EX1
  imports BOOL

  syntax Stmt ::= "{" Stmt "}" [format(%1%i%n%2%d%n%3), colors(cyan, cyan)]
                | "{" "}" [format(%1%2), colors(cyan, cyan)]
                > right:
                  Stmt Stmt [format(%1%n%2)]
                | "if" "(" Bool ")" Stmt [format(%1 %2%3%4 %5), colors(magenta, cyan, cyan)]
                | "if" "(" Bool ")" Stmt "else" Stmt
                    [avoid, format(%1 %2%3%4 %5 %6 %7), colors(magenta, cyan, cyan, magenta)]
endmodule
