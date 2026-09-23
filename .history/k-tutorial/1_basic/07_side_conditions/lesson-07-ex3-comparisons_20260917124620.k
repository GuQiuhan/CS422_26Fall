// Exercise 3: implement ==, <, <=, >, >= for Int without using any of
// K's built-in integer comparison functions (==Int, <Int, <=Int, >Int,
// >=Int, =/=Int). We only use +Int, -Int, and pattern matching.
//
// The key ideas:
//  - equality is tested by matching the same variable twice in the LHS
//    pattern (`myEqualInt(I, I)`), which only succeeds when both
//    arguments are the same value -- no comparison function needed.
//  - "less than" is reduced to testing the *sign* of I2 -Int I1. To find
//    the sign of a difference D without comparing it to 0, `race` counts
//    up from 0 and down from 0 simultaneously (Up, Down), one step at a
//    time, and checks whether Up or Down reaches D first. If D > 0, Up
//    reaches it after D steps; if D < 0, Down reaches it after |D|
//    steps. This always terminates because D is a fixed finite integer.
module LESSON-07-EX3-COMPARISONS
  imports BOOL
  imports INT-SYNTAX

  syntax Bool ::= myEqualInt(Int, Int) [function]
  rule myEqualInt(I, I) => true
  rule myEqualInt(_, _) => false [owise]

  syntax Bool ::= race(Int, Int, Int) [function]
  // race(D, Up, Down): true if D > 0, false if D < 0. Never called with D == 0.
  rule race(D, D, _) => true
  rule race(D, _, D) => false
  rule race(D, Up, Down) => race(D, Up +Int 1, Down -Int 1) [owise]

  syntax Bool ::= myLessThanInt(Int, Int) [function]
  rule myLessThanInt(I, I) => false
  rule myLessThanInt(I1, I2) => race(I2 -Int I1, 0, 0) [owise]

  syntax Bool ::= myLessOrEqualInt(Int, Int) [function]
  rule myLessOrEqualInt(I1, I2) => myLessThanInt(I1, I2) orBool myEqualInt(I1, I2)

  syntax Bool ::= myGreaterThanInt(Int, Int) [function]
  rule myGreaterThanInt(I1, I2) => myLessThanInt(I2, I1)

  syntax Bool ::= myGreaterOrEqualInt(Int, Int) [function]
  rule myGreaterOrEqualInt(I1, I2) => myLessOrEqualInt(I2, I1)
endmodule
