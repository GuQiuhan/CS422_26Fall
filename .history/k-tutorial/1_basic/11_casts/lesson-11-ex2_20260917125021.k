// Exercise 2: rework the calculator from Lesson 1.9, Exercise 2 to use a
// single `Exp` sort (subsorting `Int` and `Bool`), in the style of
// LESSON-11-E, with an `eval` function that reduces any `Exp` to a `Bool`
// or an `Int`.
module LESSON-11-EX2-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= Int [group(atom)]
               | Bool [group(atom)]
               | "(" Exp ")" [group(atom), bracket]
               | "-" Exp [group(neg)]
               > left:
                 Exp "*" Exp [group(mul)]
               | Exp "/" Exp [group(mul)]
               > left:
                 Exp "+" Exp [group(add)]
               | Exp "-" Exp [group(add)]

  syntax Exp ::= "!" Exp [group(not)]
               > non-assoc:
                 Exp "<" Exp [group(cmp)]
               | Exp "<=" Exp [group(cmp)]
               | Exp ">" Exp [group(cmp)]
               | Exp ">=" Exp [group(cmp)]
               | Exp "==" Exp [group(cmp)]
               | Exp "!=" Exp [group(cmp)]
               > left:
                 Exp "&&" Exp [group(booland)]
               | Exp "^" Exp [group(boolxor)]
               | Exp "||" Exp [group(boolor)]

  syntax priority atom > neg > mul > add > not > cmp > booland > boolxor > boolor
endmodule

module LESSON-11-EX2
  imports LESSON-11-EX2-SYNTAX
  imports INT
  imports BOOL

  syntax Exp ::= eval(Exp) [function]

  rule eval(I:Int) => I
  rule eval(B:Bool) => B

  rule eval(- E) => 0 -Int {eval(E)}:>Int
  rule eval(E1 * E2) => {eval(E1)}:>Int *Int {eval(E2)}:>Int
  rule eval(E1 / E2) => {eval(E1)}:>Int /Int {eval(E2)}:>Int requires {eval(E2)}:>Int =/=Int 0
  rule eval(E1 + E2) => {eval(E1)}:>Int +Int {eval(E2)}:>Int
  rule eval(E1 - E2) => {eval(E1)}:>Int -Int {eval(E2)}:>Int

  rule eval(E1 < E2) => {eval(E1)}:>Int <Int {eval(E2)}:>Int
  rule eval(E1 <= E2) => {eval(E1)}:>Int <=Int {eval(E2)}:>Int
  rule eval(E1 > E2) => {eval(E1)}:>Int >Int {eval(E2)}:>Int
  rule eval(E1 >= E2) => {eval(E1)}:>Int >=Int {eval(E2)}:>Int
  rule eval(E1 == E2) => {eval(E1)}:>Int ==Int {eval(E2)}:>Int
  rule eval(E1 != E2) => {eval(E1)}:>Int =/=Int {eval(E2)}:>Int

  rule eval(! E) => notBool {eval(E)}:>Bool
  rule eval(E1 && E2) => {eval(E1)}:>Bool andBool {eval(E2)}:>Bool
  rule eval(E1 ^ E2) => {eval(E1)}:>Bool xorBool {eval(E2)}:>Bool
  rule eval(E1 || E2) => {eval(E1)}:>Bool orBool {eval(E2)}:>Bool
endmodule
