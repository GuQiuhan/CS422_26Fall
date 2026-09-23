module LESSON-11-A
  imports INT

  syntax Exp ::= Int | Exp "+" Exp
  syntax Stmt ::= "if" "(" Exp ")" Stmt | "{" "}"
endmodule

module LESSON-11-B
  imports LESSON-11-A
  imports BOOL

  syntax Term ::= Exp | Stmt
  syntax Bool ::= isExpression(Term) [function]
                | isStatement(Term) [function]

  rule isExpression(_E:Exp) => true
  rule isExpression(_) => false [owise]

  rule isStatement(_S:Stmt) => true
  rule isStatement(_) => false [owise]
endmodule
