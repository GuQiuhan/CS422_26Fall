// Exercise 3: specify and verify
//   while ( 0 < $b ) {
//       $a = $a + $c;
//       $b = $b - 1;
//       $c = $c - 1;
//   }
// assuming a non-negative initial value of $b.
//
// Each of the B0 iterations decrements $b and $c by 1 and adds the
// (decreasing) value of $c to $a. Working out the closed form: on
// iteration i (1-indexed), $c has already been decremented i-1 times, so
// $a increases by (C0 - (i-1)). Summing over i = 1..B0:
//   total increase in $a = B0*C0 - (0 + 1 + ... + (B0-1))
//                          = B0*C0 - (B0*(B0-1))/2
// and $c decreases by B0, while $b ends at 0.
requires "lesson-22.k"
requires "domains.md"

module LESSON-22-EX3-SPEC-SYNTAX
    imports LESSON-22-SYNTAX

    syntax Id ::= "$a" [token]
                | "$b" [token]
                | "$c" [token]
endmodule

module LESSON-22-EX3-VERIFICATION
    imports K-EQUAL
    imports LESSON-22-EX3-SPEC-SYNTAX
    imports LESSON-22
    imports MAP-SYMBOLIC
endmodule

module LESSON-22-EX3-SPEC
    imports LESSON-22-EX3-VERIFICATION

    claim
        <k>
            while ( 0 < $b ) {
                $a = $a + $c;
                $b = $b - 1;
                $c = $c - 1;
            } => . ...
        </k>
        <store>
            $a |-> (A:Int => A +Int (B *Int C) -Int ((B *Int (B -Int 1)) /Int 2))
            $b |-> (B:Int => 0)
            $c |-> (C:Int => C -Int B)
        </store>
        requires B >=Int 0
endmodule
