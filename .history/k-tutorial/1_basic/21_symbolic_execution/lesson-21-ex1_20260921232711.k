// Exercise 1: add a rule rewriting odd integers greater than ten to a
// symbolic even integer strictly between 0 and 10.
//
// Prediction: symbolically running `0` with `--backend haskell` produces
// THREE disjuncts (instead of two), because after `0 => ?X:Int` (with
// `?X =/=Int 0`), `?X` now has three mutually-exclusive fates depending
// on which of the two bottom rules apply to it:
//   1. `?X >=Int 10` and `?X` even (or `?X >=Int 10` in a way that
//      doesn't satisfy the new rule's odd-and->10 side condition) -- only
//      the original `[rule2]` fires: `?X => 5`.
//   2. `?X >=Int 10` AND `?X` odd -- BOTH `[rule2]` (=> 5) and the new
//      `[rule3]` (=> fresh symbolic even `?Y`, 0 < ?Y < 10) are
//      simultaneously applicable; since `?X` is symbolic, the Haskell
//      backend branches on both possibilities, so this case alone
//      produces two further disjuncts: `?X => 5` and
//      `?X => ?Y:Int` (with `?Y` even, 0 < ?Y < 10).
//   3. `?X <Int 10` (and `?X =/=Int 0`) -- neither rule applies, so
//      execution gets stuck with `?X` itself in the `<k>` cell (same as
//      the original second disjunct).
// So overall the "applies" branch of the very first rule further splits
// into up to 3 sub-cases (rule2 alone, rule2-or-rule3 both possible when
// odd, stuck), for potentially 3-4 total disjuncts once the SMT solver
// prunes any branches whose constraints turn out to be infeasible
// (e.g. "odd AND even" is never simultaneously true for a single `?X`,
// so the branches are disjoint, not additionally combined).
module LESSON-21-EX1
    imports INT

    rule <k> 0 => ?X:Int ... </k> ensures ?X =/=Int 0
    rule <k> X:Int => 5  ... </k> requires X >=Int 10
    rule <k> X:Int => ?Y:Int ... </k>
      requires X >Int 10 andBool X %Int 2 =/=Int 0
      ensures ?Y >Int 0 andBool ?Y <Int 10 andBool ?Y %Int 2 ==Int 0
endmodule
