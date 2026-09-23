
module LESSON-15-EX1-DIVFLAG-SYNTAX
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

  syntax priority atom > neg > mul > add

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

  syntax priority add > not
  syntax priority not > cmp > booland > boolxor > boolor
endmodule

module LESSON-15-EX1-DIVFLAG
  imports LESSON-15-EX1-DIVFLAG-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>
                <divint> $DIVINT:Bool </divint>

  rule <k> - I:Int => 0 -Int I ...</k>
  rule <k> I1:Int * I2:Int => I1 *Int I2 ...</k>
  rule <k> I1:Int + I2:Int => I1 +Int I2 ...</k>
  rule <k> I1:Int - I2:Int => I1 -Int I2 ...</k>

  rule <k> I1:Int / I2:Int => I1 /Int I2 ...</k>
       <divint> false </divint>
    requires I2 =/=Int 0
  rule <k> I1:Int / I2:Int => I1 divInt I2 ...</k>
       <divint> true </divint>
    requires I2 =/=Int 0

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

  syntax Bool ::= isKResult(K) [function, symbol]
  rule isKResult(_:Val) => true
  rule isKResult(_) => false [owise]
endmodule
