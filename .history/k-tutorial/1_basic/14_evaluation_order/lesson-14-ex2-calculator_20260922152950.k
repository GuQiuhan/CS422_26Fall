
module LESSON-14-EX2-CALCULATOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Val ::= Int | Bool

  syntax Exp ::= Val [group(atom)]
               | "(" Exp ")" [group(atom), bracket]
               | "-" Exp [group(neg), seqstrict]
               > left:
                 Exp "*" Exp [group(mul), seqstrict]
               | Exp "/" Exp [group(mul), seqstrict]
               > left:
                 Exp "+" Exp [group(add), seqstrict]
               | Exp "-" Exp [group(add), seqstrict]

  // syntax priority atom > neg > mul > add

  syntax Exp ::= "!" Exp [group(not), seqstrict]
               > non-assoc:
                 Exp "<" Exp [group(cmp), seqstrict]
               | Exp "<=" Exp [group(cmp), seqstrict]
               | Exp ">" Exp [group(cmp), seqstrict]
               | Exp ">=" Exp [group(cmp), seqstrict]
               | Exp "==" Exp [group(cmp), seqstrict]
               | Exp "!=" Exp [group(cmp), seqstrict]
               > left:
                 Exp "&&" Exp [group(booland), seqstrict]
               | Exp "^" Exp [group(boolxor), seqstrict]
               | Exp "||" Exp [group(boolor), seqstrict]

  // syntax priority not > cmp
  // syntax priority add > not
  // syntax priority cmp > booland > boolxor > boolor
endmodule

module LESSON-14-EX2-CALCULATOR
  imports LESSON-14-EX2-CALCULATOR-SYNTAX
  imports INT
  imports BOOL

  rule <k> - I:Int => 0 -Int I ...</k>
  rule <k> I1:Int * I2:Int => I1 *Int I2 ...</k>
  rule <k> I1:Int / I2:Int => I1 /Int I2 ...</k> requires I2 =/=Int 0
  rule <k> I1:Int + I2:Int => I1 +Int I2 ...</k>
  rule <k> I1:Int - I2:Int => I1 -Int I2 ...</k>

  rule <k> I1:Int < I2:Int => I1 <Int I2 ...</k>
  rule <k> I1:Int <= I2:Int => I1 <=Int I2 ...</k>
  rule <k> I1:Int > I2:Int => I1 >Int I2 ...</k>
  rule <k> I1:Int >= I2:Int => I1 >=Int I2 ...</k>
  rule <k> I1:Int == I2:Int => I1 ==Int I2 ...</k>
  rule <k> I1:Int != I2:Int => I1 =/=Int I2 ...</k>

  rule <k> ! B:Bool => notBool B ...</k>
  rule <k> B1:Bool && B2:Bool => B1 andBool B2 ...</k>
  rule <k> B1:Bool ^ B2:Bool => B1 xorBool B2 ...</k>
  rule <k> B1:Bool || B2:Bool => B1 orBool B2 ...</k>

  syntax Bool ::= isKResult(K) [function, symbol(isKResult)]
  rule isKResult(_:Val) => true
  rule isKResult(_) => false [owise]
endmodule
