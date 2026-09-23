// Exercise (Semantic Lists): add the function's Id to each stackFrame,
// and a printStackTrace(List) function returning a String. `trace()` is
// a new Exp that evaluates to the current stack trace as a String.
module LESSON-16-EX-B-STACKTRACE-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX
  imports STRING-SYNTAX

  syntax Exp ::= Id "(" ")" | Int | String | "trace" "(" ")"
  syntax Stmt ::= "return" Exp ";" [strict]
  syntax Decl ::= "fun" Id "(" ")" "{" Stmt "}"
  syntax Pgm ::= List{Decl,""}
  syntax Id ::= "main" [token]
endmodule

module LESSON-16-EX-B-STACKTRACE
  imports LESSON-16-EX-B-STACKTRACE-SYNTAX
  imports BOOL
  imports LIST
  imports STRING

  configuration <T>
                  <k> $PGM:Pgm ~> main () </k>
                  <functions> .Map </functions>
                  <fstack> .List </fstack>
                </T>

  // declaration sequence
  rule <k> D:Decl P:Pgm => D ~> P ...</k>
  rule <k> .Pgm => . ...</k>

  // function definitions
  rule <k> fun X:Id () { S } => . ...</k>
       <functions>... .Map => X |-> S ...</functions>

  // function call
  syntax KItem ::= stackFrame(Id, K)
  rule <k> X:Id () ~> K => S </k>
       <functions>... X |-> S ...</functions>
       <fstack> .List => ListItem(stackFrame(X, K)) ...</fstack>

  // return statement
  rule <k> return I:Int ; ~> _ => I ~> K </k>
       <fstack> ListItem(stackFrame(_, K)) => .List ...</fstack>

  // stack trace
  syntax String ::= printStackTrace(List) [function]
  rule printStackTrace(.List) => ""
  rule printStackTrace(ListItem(stackFrame(X, _)) L:List) =>
       Id2String(X) +String "\n" +String printStackTrace(L)

  rule <k> trace() => printStackTrace(F) ...</k>
       <fstack> F </fstack>

  syntax Bool ::= isKResult(K) [function, symbol]
  rule isKResult(_:Int) => true
  rule isKResult(_:String) => true
  rule isKResult(_) => false [owise]
endmodule
