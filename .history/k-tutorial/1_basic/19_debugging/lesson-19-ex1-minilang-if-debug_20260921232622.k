// Exercise 1: same as Lesson 1.18, Exercise 2's minilang, but with `+`
// and `-` added (with rule labels, so we have both an "addition" rule to
// break on, and a "subtraction" rule to `k match` against once we're
// stopped on an addition term).
//
// Compile with:
//   kompile lesson-19-ex1-minilang-if-debug.k --enable-llvm-debug
// Then, e.g.:
//   krun minilang-if-debug.pgm --debugger
//   (gdb) break LESSON-19-EX1-MINILANG-IF-DEBUG.isKResult.rhs
//   (gdb) run
//   ... observe the subject/argument at that breakpoint ...
//   (gdb) break LESSON-19-EX1-MINILANG-IF-DEBUG.addition.rhs
//   (gdb) k start
//   (gdb) k step ... (until an `Exp + Exp` term with two Int operands is at the top of <k>)
//   (gdb) k match LESSON-19-EX1-MINILANG-IF-DEBUG.subtraction subject
module LESSON-19-EX1-MINILANG-IF-DEBUG-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Exp ::= Id | Int | Bool | Id "(" ")"
               | Exp "==" Exp [seqstrict]
               > left:
                 Exp "+" Exp [seqstrict]
               | Exp "-" Exp [seqstrict]
  syntax Stmt ::= "return" Exp ";" [strict]
                | Id "=" Exp ";" [strict(2)]
                | "if" "(" Exp ")" "{" Decls "}" "else" "{" Decls "}" [strict(1)]
  syntax Decl ::= "int" Id ";"
                | "fun" Id "(" ")" "{" Decls "}"
                | Stmt
  syntax Decls ::= List{Decl,""}
  syntax Id ::= "main" [token]
endmodule

module LESSON-19-EX1-MINILANG-IF-DEBUG
  imports LESSON-19-EX1-MINILANG-IF-DEBUG-SYNTAX
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

  rule [decl-seq]: <k> D:Decl Ds:Decls => D ~> Ds ...</k>
  rule [decl-done]: <k> .Decls => . ...</k>

  rule [fun-decl]: <k> fun X:Id () { Body } => . ...</k>
       <functions>... .Map => X |-> Body ...</functions>

  rule [var-decl]: <k> int X:Id ; => . ...</k>
       <state> STATE => STATE [ X <- 0 ] </state>

  rule [lookup]: <k> X:Id => I ...</k>
       <state>... X |-> I ...</state>

  rule [assign]: <k> X:Id = I:Int ; => . ...</k>
       <state>... X |-> (_ => I) ...</state>

  rule [eq-int]: <k> I1:Int == I2:Int => I1 ==K I2 ...</k>
  rule [eq-bool]: <k> B1:Bool == B2:Bool => B1 ==K B2 ...</k>

  rule [addition]: <k> I1:Int + I2:Int => I1 +Int I2 ...</k>
  rule [subtraction]: <k> I1:Int - I2:Int => I1 -Int I2 ...</k>

  rule [if-stmt]: <k> if (B:Bool) { Ds1 } else { Ds2 } => #if B #then Ds1 #else Ds2 #fi ...</k>

  syntax KItem ::= stackFrame(K, Map)
  rule [call]: <k> X:Id () ~> K => Body </k>
       <functions>... X |-> Body ...</functions>
       <state> STATE => .Map </state>
       <fstack> .List => ListItem(stackFrame(K, STATE)) ...</fstack>

  rule [return]: <k> return I:Int ; ~> _ => I ~> K </k>
       <state> _ => STATE </state>
       <fstack> ListItem(stackFrame(K, STATE)) => .List ...</fstack>

  syntax Bool ::= isKResult(K) [function, symbol]
  rule [is-int]: isKResult(_:Int) => true
  rule [is-bool]: isKResult(_:Bool) => true
  rule [is-owise]: isKResult(_) => false [owise]
endmodule
