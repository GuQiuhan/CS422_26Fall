// Exercise 2: add an `if` Stmt to the Lesson 1.16, Exercise 1 minilang,
// implemented with `#if`. Also adds a `==` comparison operator so `if`
// conditions have something to test.
module LESSON-18-EX2-MINILANG-IF-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Exp ::= Id | Int | Bool | Id "(" ")"
               | Exp "==" Exp [seqstrict]
  syntax Stmt ::= "return" Exp ";" [strict]
                | Id "=" Exp ";" [strict(2)]
                | "if" "(" Exp ")" "{" Decls "}" "else" "{" Decls "}" [strict(1)]
  syntax Decl ::= "int" Id ";"
                | "fun" Id "(" ")" "{" Decls "}"
                | Stmt
  syntax Decls ::= List{Decl,""}
  syntax Id ::= "main" [token]
endmodule

module LESSON-18-EX2-MINILANG-IF
  imports LESSON-18-EX2-MINILANG-IF-SYNTAX
  imports BOOL
  imports MAP
  imports LIST
  imports K-EQUAL

  configuration <T>
                  <k> $PGM:Decls ~> main () </k>
                  <functions> .Map </functions>
                  <state> .Map </state>
                  <fstack> .List </fstack>
                </T>

  // declaration/statement sequence
  rule <k> D:Decl Ds:Decls => D ~> Ds ...</k>
  rule <k> .Decls => . ...</k>

  // function declaration (top level only)
  rule <k> fun X:Id () { Body } => . ...</k>
       <functions>... .Map => X |-> Body ...</functions>

  // local variable declaration, initialized to 0
  rule <k> int X:Id ; => . ...</k>
       <state> STATE => STATE [ X <- 0 ] </state>

  // variable lookup
  rule <k> X:Id => I ...</k>
       <state>... X |-> I ...</state>

  // assignment
  rule <k> X:Id = I:Int ; => . ...</k>
       <state>... X |-> (_ => I) ...</state>

  // equality comparison
  rule <k> I1:Int == I2:Int => I1 ==K I2 ...</k>
  rule <k> B1:Bool == B2:Bool => B1 ==K B2 ...</k>

  // if statement
  rule <k> if (B:Bool) { Ds1 } else { Ds2 } => #if B #then Ds1 #else Ds2 #fi ...</k>

  // call: push a stack frame saving the remaining continuation and the
  // caller's environment, then switch to a fresh environment and run the
  // callee's body
  syntax KItem ::= stackFrame(K, Map)
  rule <k> X:Id () ~> K => Body </k>
       <functions>... X |-> Body ...</functions>
       <state> STATE => .Map </state>
       <fstack> .List => ListItem(stackFrame(K, STATE)) ...</fstack>

  // return: pop the stack frame, restore the caller's environment, and
  // resume the caller's continuation with the returned value
  rule <k> return I:Int ; ~> _ => I ~> K </k>
       <state> _ => STATE </state>
       <fstack> ListItem(stackFrame(K, STATE)) => .List ...</fstack>

  syntax Bool ::= isKResult(K) [function, symbol]
  rule isKResult(_:Int) => true
  rule isKResult(_:Bool) => true
  rule isKResult(_) => false [owise]
endmodule
