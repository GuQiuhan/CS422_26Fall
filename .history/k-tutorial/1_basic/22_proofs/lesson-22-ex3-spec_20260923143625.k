
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
