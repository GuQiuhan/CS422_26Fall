// Exercise 2: same calculator as Lesson 1.6, Exercise 2, but the `/` rule
// requires the denominator to be non-zero, so it simply does not match
// (rather than getting stuck evaluating `/Int` on a zero denominator,
// which would crash krun with a "Division by zero" exception) when
// dividing by zero.
module LESSON-07-EX2-NODIVZERO-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= Int [group(atom)]
               | "(" Exp ")" [group(atom), bracket]
               | "-" Exp [group(neg), function]
               > left:
                 Exp "*" Exp [group(mul), function]
               | Exp "/" Exp [group(mul), function]
               > left:
                 Exp "+" Exp [group(add), function]
               | Exp "-" Exp [group(add), function]

  syntax priority atom > neg > mul > add

  syntax Bool ::= "(" Bool ")" [bracket]
                > "!" Bool [function]
                > non-assoc:
                  Exp "<" Exp [function]
                | Exp "<=" Exp [function]
                | Exp ">" Exp [function]
                | Exp ">=" Exp [function]
                | Exp "==" Exp [function]
                | Exp "!=" Exp [function]
                > left:
                  Bool "&&" Bool [function]
                | Bool "^" Bool [function]
                | Bool "||" Bool [function]
endmodule

module LESSON-07-EX2-NODIVZERO
  imports LESSON-07-EX2-NODIVZERO-SYNTAX
  imports INT
  imports BOOL

  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2 requires I2 =/=Int 0
  rule I1 + I2 => I1 +Int I2
  rule I1 - I2 => I1 -Int I2

  rule I1 < I2 => I1 <Int I2
  rule I1 <= I2 => I1 <=Int I2
  rule I1 > I2 => I1 >Int I2
  rule I1 >= I2 => I1 >=Int I2
  rule I1 == I2 => I1 ==Int I2
  rule I1 != I2 => I1 =/=Int I2

  rule ! B => notBool B
  rule B1 && B2 => B1 andBool B2
  rule B1 ^ B2 => B1 xorBool B2
  rule B1 || B2 => B1 orBool B2
endmodule
