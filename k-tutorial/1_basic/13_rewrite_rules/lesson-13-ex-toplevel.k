
module LESSON-13-EX-TOPLEVEL
  imports INT
  imports BOOL

  syntax Exp ::= Int | Bool | Exp "+" Exp | Exp "&&" Exp


  rule <k> I1:Int + _I2:Int => I1 ...</k>
  rule <k> _I1:Int + I2:Int => I2 ...</k>


  rule <k> 1 => 100 ...</k>
endmodule
