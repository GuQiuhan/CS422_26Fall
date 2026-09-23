// Exercises 1: arithmetic calculator with evaluation rules
module LESSON-06-EX-CALC1-SYNTAX
  imports INT-SYNTAX

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
endmodule

module LESSON-06-EX-CALC1
  imports LESSON-06-EX-CALC1-SYNTAX
  imports INT

  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2
  rule I1 + I2 => I1 +Int I2
  rule I1 - I2 => I1 -Int I2
endmodule
