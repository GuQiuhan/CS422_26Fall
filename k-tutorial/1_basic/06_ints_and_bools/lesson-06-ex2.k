module LESSON-06-EX2-SYNTAX
  imports BOOL-SYNTAX

  syntax Bool ::= "(" Bool ")" [bracket]
                > "!" Bool [function]
                > left:
                  Bool "&&" Bool [function]
                | Bool "^" Bool [function]
                | Bool "||" Bool [function]
                > right:
                  Bool "->" Bool [function]
endmodule

module LESSON-06-EX2
  imports LESSON-06-EX2-SYNTAX
  imports BOOL

  rule ! B => notBool B
  rule A && B => A andBool B
  rule A ^ B => A xorBool B
  rule A || B => A orBool B
  rule A -> B => A impliesBool B
endmodule
