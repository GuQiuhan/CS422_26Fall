module LESSON-06-EX-CALC2-SYNTAX
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

module LESSON-06-EX-CALC2
  imports LESSON-06-EX-CALC2-SYNTAX
  imports INT
  imports BOOL

  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2
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
