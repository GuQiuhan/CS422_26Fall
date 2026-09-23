// Exercise 2: same claim as 3.3, but with postcondition
// `ensures (?C ==Int maxInt(A, B))`, using two simplifications that
// capture the meaning of maxInt.
requires "lesson-22.k"
requires "domains.md"

module LESSON-22-EX2-SPEC-SYNTAX
    imports LESSON-22-SYNTAX

    syntax Id ::= "$a" [token]
                | "$b" [token]
                | "$c" [token]
endmodule

module LESSON-22-EX2-VERIFICATION
    imports K-EQUAL
    imports LESSON-22-EX2-SPEC-SYNTAX
    imports LESSON-22
    imports MAP-SYMBOLIC

    rule { M:Map [ K <- V ] #Equals M [ K <- V' ] } => { V #Equals V' } [simplification]

    // The meaning of maxInt(A, B): it equals B when A < B, and A otherwise.
    rule maxInt(A:Int, B:Int) => B requires A <Int B [simplification]
    rule maxInt(A:Int, B:Int) => A requires A >=Int B [simplification]
endmodule

module LESSON-22-EX2-SPEC
    imports LESSON-22-EX2-VERIFICATION

    claim <k> $a = A:Int ; $b = B:Int ;
              if ($a < $b) {
                $c = $b ;
              } else {
                $c = $a ;
              }
            => . ... </k>
            <store> STORE => STORE [ $a <- A ] [ $b <- B ] [ $c <- ?C:Int ] </store>
        ensures ?C ==Int maxInt(A, B)
endmodule
