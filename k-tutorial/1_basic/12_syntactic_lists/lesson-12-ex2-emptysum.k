
module LESSON-12-EX2-EMPTYSUM-SYNTAX
  imports INT-SYNTAX

  syntax Ints ::= List{Int,","}
endmodule

module LESSON-12-EX2-EMPTYSUM
  imports LESSON-12-EX2-EMPTYSUM-SYNTAX
  imports INT

  syntax Int ::= sum(Ints) [function]
  rule sum(.Ints) => 0
  rule sum(I:Int) => I
  rule sum(I1:Int, I2:Int, Is:Ints) => sum(I1 +Int I2, Is)
endmodule
