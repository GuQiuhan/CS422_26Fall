
module LESSON-18-EX1-EQINT
  imports INT
  imports BOOL
  imports K-EQUAL

  syntax Int ::= eqInt(K, K) [function]
  rule eqInt(A, B) => #if A ==K B #then 0 #else 1 #fi
endmodule
