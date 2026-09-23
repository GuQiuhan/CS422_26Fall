module LESSON-09-EX2-CALCULATOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= Int [group(atom)]
               | "(" Exp ")" [group(atom), bracket, format(%1%2%3)]
               | "-" Exp [group(neg), function, format(%1%2), color(yellow)]
               > left:
                 Exp "*" Exp [group(mul), function, format(%1 %2 %3), color(yellow)]
               | Exp "/" Exp [group(mul), function, format(%1 %2 %3), color(yellow)]
               > left:
                 Exp "+" Exp [group(add), function, format(%1 %2 %3), color(yellow)]
               | Exp "-" Exp [group(add), function, format(%1 %2 %3), color(yellow)]

  syntax priority atom > neg > mul > add

  syntax Bool ::= "(" Bool ")" [bracket, format(%1%2%3)]
                > "!" Bool [function, format(%1%2), color(green)]
                > non-assoc:
                  Exp "<" Exp [function, format(%1 %2 %3), color(magenta)]
                | Exp "<=" Exp [function, format(%1 %2 %3), color(magenta)]
                | Exp ">" Exp [function, format(%1 %2 %3), color(magenta)]
                | Exp ">=" Exp [function, format(%1 %2 %3), color(magenta)]
                | Exp "==" Exp [function, format(%1 %2 %3), color(magenta)]
                | Exp "!=" Exp [function, format(%1 %2 %3), color(magenta)]
                > left:
                  Bool "&&" Bool [function, format(%1 %2 %3), color(green)]
                | Bool "^" Bool [function, format(%1 %2 %3), color(green)]
                | Bool "||" Bool [function, format(%1 %2 %3), color(green)]
endmodule

module LESSON-09-EX2-CALCULATOR
  imports LESSON-09-EX2-CALCULATOR-SYNTAX
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
