module LESSON-07-EX-ISEVEN
  imports BOOL
  imports INT

  syntax Bool ::= isEven(Int) [function]

  rule isEven(I) => true requires I %Int 2 ==Int 0
  rule isEven(I) => false requires I %Int 2 =/=Int 0
endmodule
