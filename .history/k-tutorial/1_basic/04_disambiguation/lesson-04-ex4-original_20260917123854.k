// Original grammar from the exercise, kept for comparison with
// lesson-04-ex4.k. Parsing ex4.expr ("abb") with this module reports no
// ambiguity, for the reason explained in lesson-04-ex4.k.
module EXERCISE4

  syntax Expr ::= "a" Expr "b"
                | "abb"
                | "b"

endmodule
