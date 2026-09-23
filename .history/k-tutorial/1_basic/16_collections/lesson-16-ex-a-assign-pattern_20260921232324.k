// Exercise (Maps), version 2: variable assignment via a map pattern
// (matching the old value in place and rewriting just that binding).
module LESSON-16-EX-A-ASSIGN-PATTERN-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  syntax Exp ::= Id | Int
  syntax Decl ::= "int" Id "=" Exp ";" [strict(2)]
  syntax Stmt ::= Id "=" Exp ";" [strict(2)]
  syntax Decl ::= Stmt
  syntax Pgm ::= List{Decl,""}
endmodule

module LESSON-16-EX-A-ASSIGN-PATTERN
  imports LESSON-16-EX-A-ASSIGN-PATTERN-SYNTAX
  imports BOOL

  configuration <T>
                  <k> $PGM:Pgm </k>
                  <state> .Map </state>
                </T>

  rule <k> D:Decl P:Pgm => D ~> P ...</k>
  rule <k> .Pgm => . ...</k>

  rule <k> int X:Id = I:Int ; => . ...</k>
       <state> STATE => STATE [ X <- I ] </state>

  rule <k> X:Id = I:Int ; => . ...</k>
       <state>... X |-> (_ => I) ...</state>

  rule <k> X:Id => I ...</k>
       <state>... X |-> I ...</state>

  syntax Bool ::= isKResult(K) [symbol, function]
  rule isKResult(_:Int) => true
  rule isKResult(_) => false [owise]
endmodule
