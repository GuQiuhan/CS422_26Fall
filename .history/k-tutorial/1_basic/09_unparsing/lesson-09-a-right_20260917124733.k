// Exercise: make the binary operators right-associative and observe how
// unparsing `exp.bool` differs.
//
// With `left:`, `true && false && !true` parses as
// `(true && false) && !true`. Because `&&` is left-associative, this is
// the *only* valid parse, so no parentheses are needed when unparsing it.
//
// With `right:`, the same text `true && false && !true` instead parses
// as `true && (false && !true)`. That AST, if written back out as plain
// `true && false && !true` (no parens), would be re-parsed -- under the
// same right-associative grammar -- back into `true && (false && !true)`
// again, so no parens are *needed* here either... but K's unparser does
// not attempt that global reasoning; it locally checks whether the RIGHT
// child of a left-associative-sensitive position needs protecting. Since
// the grammar is now right-associative, `&&` can no longer appear as the
// direct *left* child of `&&`/`^`/`||` at the same priority, so whenever
// the original AST's left child is itself one of these operators, the
// unparser must now wrap it in explicit parentheses to preserve the
// grouping, e.g. `(true && false) && !true` becomes unparsed with
// parentheses around `true && false`.
module LESSON-09-A-RIGHT
  imports BOOL

  syntax Exp ::= "(" Exp ")" [bracket]
               | Bool
               > "!" Exp
               > right:
                 Exp "&&" Exp
               | Exp "^" Exp
               | Exp "||" Exp

  syntax Exp ::= id(Exp) [function]
  rule id(E) => E
endmodule
