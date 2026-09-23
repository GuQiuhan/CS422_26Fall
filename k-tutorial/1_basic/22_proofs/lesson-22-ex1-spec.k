// Exercise 1: change the if-condition from 3.2 so that it takes the else
// branch, and adjust the claim's postcondition to match.
requires "lesson-22.k"
requires "domains.md"

module LESSON-22-EX1-SPEC-SYNTAX
    imports LESSON-22-SYNTAX

    syntax Id ::= "$a" [token]
endmodule

module LESSON-22-EX1-VERIFICATION
    imports K-EQUAL
    imports LESSON-22-EX1-SPEC-SYNTAX
    imports LESSON-22
    imports MAP-SYMBOLIC
endmodule

module LESSON-22-EX1-SPEC
    imports LESSON-22-EX1-VERIFICATION

    claim <k> if ( 3 + 4 == 8 ) {
                $a = 1 ;
                } else {
                $a = 2 ;
                }
            => . ... </k>
            <store> STORE => STORE [ $a <- 2 ] </store>
endmodule
