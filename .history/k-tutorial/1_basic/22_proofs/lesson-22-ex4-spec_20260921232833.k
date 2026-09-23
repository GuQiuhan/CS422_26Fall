// Exercise 4: two interacting functions -- $inc(x) returns x + 1, and
// $addTwo(x) calls $inc twice (nested calls) to return x + 2. Proves
// that nested/reentrant function calls compose correctly through the
// <stack> cell.
requires "lesson-22.k"
requires "domains.md"

module LESSON-22-EX4-SPEC-SYNTAX
    imports LESSON-22-SYNTAX

    syntax Id ::= "$inc" [token]
                | "$addTwo" [token]
                | "$x" [token]
                | "$r" [token]
endmodule

module LESSON-22-EX4-VERIFICATION
    imports K-EQUAL
    imports LESSON-22-EX4-SPEC-SYNTAX
    imports LESSON-22
    imports MAP-SYMBOLIC
endmodule

module LESSON-22-EX4-SPEC
    imports LESSON-22-EX4-VERIFICATION

    claim
        <k>
            def $inc($x, .Ids) { return $x + 1; }
            def $addTwo($x, .Ids) { return $inc($inc($x, .Ints), .Ints); }

            $r = $addTwo(N:Int, .Ints);
        => . ... </k>
        <funcs> .Map => ?_ </funcs>
        <store> $r |-> (_ => N +Int 2) </store>
        <stack> .List </stack>
endmodule
