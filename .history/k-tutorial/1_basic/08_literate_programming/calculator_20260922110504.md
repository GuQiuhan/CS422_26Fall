# Exercise 3: A Literate Arithmetic and Boolean Calculator

This document defines a small calculator language supporting integer arithmetic (`+`, `-`, unary `-`, `*`, `/`) and Boolean expressions (`&&`, `^`, `||`, `!`), including comparisons between integer expressions (`<`, `<=`, `>`, `>=`, `==`, `!=`). 

## Syntax


```k
module CALCULATOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
```

Integer expressions are the usual atoms (integer literals and parenthesized expressions), unary negation, and the four arithmetic operators, grouped by precedence: negation binds tighter than multiplication/division, which binds tighter than addition/subtraction.
All binary operators are left-associative.

```k
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
```

Boolean expressions include the standard connectives plus comparisons between two integer expressions. Comparisons bind tighter than the
Boolean connectives, and are non-associative (so `1 < 2 < 3` is a parse error, rather than silently meaning something unintended).

```k
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
```

## Semantics


```k
module CALCULATOR
  imports CALCULATOR-SYNTAX
  imports INT
  imports BOOL
```


```k
  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2 requires I2 =/=Int 0
  rule I1 + I2 => I1 +Int I2
  rule I1 - I2 => I1 -Int I2
```


```k
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
```

Compile this file with:

```
kompile calculator.md --main-module CALCULATOR --syntax-module CALCULATOR-SYNTAX
```
