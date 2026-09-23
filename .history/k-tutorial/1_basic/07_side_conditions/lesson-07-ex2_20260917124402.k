// Exercise (owise Rules): letter-D for [60, 70), letter-F for [0, 60)
module LESSON-07-EX2
  imports BOOL
  imports INT

  syntax Grade ::= "letter-D"
                 | "letter-F"
                 | gradeFromPercentile(Int) [function]

  rule gradeFromPercentile(I) => letter-D requires I >=Int 60
  rule gradeFromPercentile(_) => letter-F [owise]
endmodule
