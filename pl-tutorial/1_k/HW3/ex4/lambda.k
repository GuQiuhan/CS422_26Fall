requires "substitution.md"

module LAMBDA-SYNTAX
  imports DOMAINS-SYNTAX
  imports KVAR-SYNTAX

  syntax Val ::= KVar
               | "lambda" KVar "." Exp  [binder]
  syntax Exp ::= Val
               | Exp Exp              [strict, left]
               | "(" Exp ")"          [bracket]

  syntax Val ::= Int | Bool
  syntax Exp ::= "-" Int
               > Exp "*" Exp          [strict, left]
               | Exp "/" Exp          [strict]
               > Exp "+" Exp          [strict, left]
               > Exp "<=" Exp         [strict]

  syntax Exp ::= "if" Exp "then" Exp "else" Exp  [strict(1)]

  syntax Exp ::= "let" KVar "=" Exp "in" Exp [macro]
  rule let X = E in E':Exp => (lambda X . E') E

  syntax Exp ::= "letrec" KVar KVar "=" Exp "in" Exp  [macro]
               | "mu" KVar "." Exp                    [binder]
  rule letrec F:KVar X = E in E' => let F = mu F . lambda X . E in E'

  syntax Exp ::= "callcc" Exp  [strict]
               | "callCC" Exp  [strict]
  syntax Val ::= cc(K)
endmodule

// Everything except the definitions of callcc and callCC.
module LAMBDA-COMMON
  imports LAMBDA-SYNTAX
  imports SUBSTITUTION
  imports DOMAINS

  // explicit, because the main module is not always LAMBDA
  configuration <k> $PGM:Exp </k>

  syntax KResult ::= Val

  rule (lambda X:KVar . E:Exp) V:Val => E[V / X]

  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2
  rule I1 + I2 => I1 +Int I2
  rule I1 <= I2 => I1 <=Int I2

  rule if true  then E else _ => E
  rule if false then _ else E => E

  rule mu X . E => E[(mu X . E) / X]

  // passing a value to a continuation: drop the rest, resume K
  rule <k> cc(K) V ~> _ => V ~> K </k>
endmodule

// The primitive semantics of each operator.
module CALLCC-PRIMITIVE
  imports LAMBDA-COMMON
  // callcc keeps the current continuation K after V cc(K)
  rule <k> (callcc V:Val => V cc(K)) ~> K </k>
endmodule

module CALL-CC-PRIMITIVE
  imports LAMBDA-COMMON
  // callCC drops the current continuation K: only V cc(K) is left
  rule <k> callCC V:Val ~> K => V cc(K) </k>
endmodule

// 1. callCC itself (callcc kept as in Lesson 1)
module LAMBDA
  imports CALLCC-PRIMITIVE
  imports CALL-CC-PRIMITIVE
endmodule

// 2. callcc in terms of callCC:
module FROM-CALL-CC-TO-CALLCC
  imports CALL-CC-PRIMITIVE
  rule callcc lambda K:KVar . E => callCC (lambda K . (K E))
endmodule

// 3. callCC in terms of callcc:
module FROM-CALLCC-TO-CALL-CC
  imports CALLCC-PRIMITIVE
  rule callCC lambda K:KVar . E => callcc (lambda K . (cc(.K) E))
endmodule
// Another way: 
//   configuration <k> callcc (lambda $exit . $PGM:Exp) </k>
// and translate callCC (lambda K . E) into callcc (lambda K . ($exit E)).
