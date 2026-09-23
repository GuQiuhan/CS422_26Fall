
module LESSON-17-EX1-FUNCTIONS-CELLCOLLECTION-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  syntax Exp ::= Id | Int | Id "(" ")"
  syntax Stmt ::= "return" Exp ";" [strict]
                | Id "=" Exp ";" [strict(2)]
  syntax Decl ::= "int" Id ";"
                | "fun" Id "(" ")" "{" Decls "}"
                | Stmt
  syntax Decls ::= List{Decl,""}
  syntax Id ::= "main" [token]
endmodule

module LESSON-17-EX1-FUNCTIONS-CELLCOLLECTION
  imports LESSON-17-EX1-FUNCTIONS-CELLCOLLECTION-SYNTAX
  imports BOOL
  imports MAP
  imports LIST

  configuration <T>
                  <k> $PGM:Decls ~> main () </k>
                  <functions>
                    <function multiplicity="*" type="Map">
                      <fname> .K </fname>
                      <fbody> .K </fbody>
                    </function>
                  </functions>
                  <state> .Map </state>
                  <fstack> .List </fstack>
                </T>

  // declaration/statement sequence
  rule <k> D:Decl Ds:Decls => D ~> Ds ...</k>
  rule <k> .Decls => . ...</k>

  // function declaration (top level only)
  rule <k> fun X:Id () { Body } => . ...</k>
       (.Bag => <function>
                  <fname> X </fname>
                  <fbody> Body </fbody>
                </function>)

  // local variable declaration, initialized to 0
  rule <k> int X:Id ; => . ...</k>
       <state> STATE => STATE [ X <- 0 ] </state>

  // variable lookup
  rule <k> X:Id => I ...</k>
       <state>... X |-> I ...</state>

  // assignment
  rule <k> X:Id = I:Int ; => . ...</k>
       <state>... X |-> (_ => I) ...</state>

  // call: push a stack frame saving the remaining continuation and the
  // caller's environment, then switch to a fresh environment and run the
  // callee's body
  syntax KItem ::= stackFrame(K, Map)
  rule <k> X:Id () ~> K => Body </k>
       <function>
         <fname> X </fname>
         <fbody> Body </fbody>
       </function>
       <state> STATE => .Map </state>
       <fstack> .List => ListItem(stackFrame(K, STATE)) ...</fstack>

  // return: pop the stack frame, restore the caller's environment, and
  // resume the caller's continuation with the returned value
  rule <k> return I:Int ; ~> _ => I ~> K </k>
       <state> _ => STATE </state>
       <fstack> ListItem(stackFrame(K, STATE)) => .List ...</fstack>

  syntax Bool ::= isKResult(K) [function, symbol]
  rule isKResult(_:Int) => true
  rule isKResult(_) => false [owise]
endmodule
