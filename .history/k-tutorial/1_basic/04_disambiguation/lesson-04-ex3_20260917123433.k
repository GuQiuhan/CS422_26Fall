// Exercise 3: an ambiguity that priority/associativity cannot resolve.
//
// Parsing "x y" is ambiguous between the two productions of `A` below:
// either the whole string matches `"x" "y"` directly, or it matches
// `"x" B` where `B` matches "y". Both parses have `A` as their top-level
// symbol -- neither is a *child* of the other -- so there is no
// parent/child relationship for a `syntax priority` (or associativity)
// declaration to apply to. Priority/associativity only restrict which
// symbols may appear as a direct child of another symbol, so they cannot
// disambiguate two independent top-level parses of the same sort. We
// resolve it instead with `prefer`, always choosing the direct production.
module LESSON-04-EX3

  syntax B ::= "y"
  syntax A ::= "x" "y" [prefer]
             | "x" B

endmodule
