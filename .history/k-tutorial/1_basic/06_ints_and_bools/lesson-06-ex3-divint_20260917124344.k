// Exercise 3: same as lesson-06-ex-calc2.k, but using `divInt` instead of
// `/Int`. `/Int` implements T-division (truncation toward zero, like C's
// `/`): the sign of the remainder matches the dividend. `divInt`
// implements E-division (Euclidean division): the remainder is always
// non-negative, i.e. `0 <= I1 modInt I2 < |I2|`. Whenever the two
// operands have different signs and the division is not exact, the two
// functions round to different quotients (E-division always rounds
// toward negative infinity in that case; T-division rounds toward zero),
// which is why `-7 / 3` and `-7 divInt 3` disagree.
module LESSON-06-EX3-DIVINT-SYNTAX
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

module LESSON-06-EX3-DIVINT
  imports LESSON-06-EX3-DIVINT-SYNTAX
  imports INT
  imports BOOL

  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 divInt I2
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
