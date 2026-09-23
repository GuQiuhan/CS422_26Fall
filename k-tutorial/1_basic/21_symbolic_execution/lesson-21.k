module LESSON-21
    imports INT

    rule <k> 0 => ?X:Int ... </k> ensures ?X =/=Int 0
    rule <k> X:Int => 5  ... </k> requires X >=Int 10
endmodule
