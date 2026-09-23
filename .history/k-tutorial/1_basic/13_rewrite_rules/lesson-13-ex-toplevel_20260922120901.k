
  imports INT
  imports BOOL

  syntax Exp ::= Int | Bool | Exp "+" Exp | Exp "&&" Exp

  // Two nondeterministic top-level rules: on `I1 + I2`, we may keep
  // either the left or the right operand.
  rule <k> I1:Int + _I2:Int => I1 ...</k>
  rule <k> _I1:Int + I2:Int => I2 ...</k>

  // A third rule that further rewrites one of the two possible results
  // (whichever one happens to be `1`) -- a concrete literal, so it fires
  // exactly once and does not loop.
  rule <k> 1 => 100 ...</k>
endmodule
