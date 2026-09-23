module LESSON-07-EX3-COMPARISONS
  imports BOOL
  imports INT-SYNTAX
  imports INT

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
