// Exercise 1: add integer division; + and / are `strict` (nondeterministic
// evaluation order) instead of `seqstrict`.
//
// Running `krun --search` on `1 / 0 + 2 / 1`:
//   `2 / 1` always reduces deterministically to `2` (its own operands are
//   already integer literals, so `/`'s `strict` heating has nothing to
//   choose between -- no branching there).
//   `1 / 0` also has already-atomic operands, so it never even needs to
//   heat; it goes straight to trying the `/` rule, whose side condition
//   `I2 =/=Int 0` fails, so the term `1 / 0` is simply *stuck*: it is not
//   a KResult (so the surrounding `+` cannot cool it back in), and it has
//   no further applicable heat/cool/evaluation rule (so nothing can make
//   progress on it either).
//   The only real nondeterminism is at the outer `+`: because it is
//   `strict`, K may heat out the left operand (`1 / 0`) first or the
//   right operand (`2 / 1`) first -- two distinct execution paths/
//   derivations. But both paths reduce `2 / 1` to `2` and leave `1 / 0`
//   stuck either way, so they both end at the *same* final configuration
//   `1 / 0 + 2`. `krun --search` therefore reports exactly **1** distinct
//   final state (a stuck one), even though there were 2 nondeterministic
//   derivation paths explored to reach it.
module LESSON-14-EX1-DIV-SYNTAX
  imports UNSIGNED-INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= Int
               | Bool
               > left: Exp "+" Exp [strict]
               | Exp "-" Exp [seqstrict]
               | Exp "/" Exp [strict]
               > left: Exp "&&" Exp [seqstrict]
endmodule

module LESSON-14-EX1-DIV
  imports LESSON-14-EX1-DIV-SYNTAX
  imports INT
  imports BOOL

  rule <k> I1:Int + I2:Int => I1 +Int I2 ...</k>
  rule <k> I1:Int - I2:Int => I1 -Int I2 ...</k>
  rule <k> I1:Int / I2:Int => I1 /Int I2 ...</k> requires I2 =/=Int 0
  rule <k> B1:Bool && B2:Bool => B1 andBool B2 ...</k>

  syntax Bool ::= isKResult(K) [function, symbol]
  rule isKResult(_:Int) => true
  rule isKResult(_:Bool) => true
  rule isKResult(_) => false [owise]
endmodule
