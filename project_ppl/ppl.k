// K interpreter for the probabilistic programming language of
// "Probabilistic Programs Semantics" (kernel-based semantics, Fig. 1 / Fig. 2).
//
// A probabilistic state (probstate) maps every program variable to a Markov
// kernel together with its direct dependency set.  Kernels are kept
// SYMBOLICALLY, exactly following Fig. 2; on top of that, the NUMERIC module
// answers queries (probability of an event, expectation of an expression) by
// composing the kernels along a topological order (Theorem 1), using grid
// integration.

module PPL-SYNTAX
  imports DOMAINS-SYNTAX
  imports FLOAT-SYNTAX

  // ---------------------------------------------------------------- Fig. 1
  // E ::= c | x | E op E          (plus ReLU, used in the paper's Fig. 3)
  syntax Exp ::= Int | Float | Id
               | "(" Exp ")"            [bracket]
               | "ReLU" "(" Exp ")"
               | "-" Exp
               > left:
                 Exp "*" Exp            [left]
               | Exp "/" Exp            [left]
               > left:
                 Exp "+" Exp            [left]
               | Exp "-" Exp            [left]
  syntax Exps ::= List{Exp, ","}

  // B ::= true | false | E = E | E != E | E < E | ... | B /\ B | B \/ B | !B
  syntax BExp ::= "true" | "false"
                | Exp "==" Exp | Exp "!=" Exp
                | Exp "<" Exp  | Exp "<=" Exp
                | Exp ">" Exp  | Exp ">=" Exp
                | "(" BExp ")"          [bracket]
                > "!" BExp
                > left: BExp "&&" BExp  [left]
                > left: BExp "||" BExp  [left]

  // D ::= Normal | Uniform | Laplace | Logistic | Exponential | Gamma
  //     | Pareto | Student-t
  syntax Dist ::= "Normal" | "Uniform" | "Laplace" | "Logistic"
                | "Exponential" | "Gamma" | "Pareto" | "Student-t"

  // s ::= skip | x := E | x ~ D(E1,...,Ek) | if B then P else P
  //     | while B do P | observe(B)
  // Branch and loop bodies are written in braces, so that "s; P" sequences
  // inside them are unambiguous.  "x = E" is accepted as sugar for "x := E"
  // (the paper's Fig. 3 writes "z = ReLU(y)").
  syntax Block ::= "{" "}" | "{" Stmts "}"
  syntax Stmt ::= "skip"
                | Id ":=" Exp
                | Id "=" Exp                [macro]
                | Id "~" Dist "(" Exps ")"
                | "if" BExp "then" Block "else" Block
                | "while" BExp "do" Block
                | "observe" "(" BExp ")"
  // queries and settings of the interpreter (not part of the paper's language)
                | "query" "prob" "(" BExp ")"
                | "query" "mean" "(" Exp ")"
                | "grid" Int

  // P ::= s | s; P        (the ";" between statements is optional)
  syntax Stmts ::= Stmt
                 | Stmt ";"
                 | Stmt Stmts
                 | Stmt ";" Stmts

  rule X:Id = E:Exp => X := E
endmodule


// ===========================================================================
// Kernels, dependency sets, and the symbolic semantics of Fig. 2
// ===========================================================================
module PPL-KERNELS
  imports PPL-SYNTAX
  imports DOMAINS

  // A kernel K_x together with dep(K_x).  The body describes the kernel:
  //   delta(E)          Dirac kernel of an expression: [[E]]p
  //   sample(D, Es)     kernel of x ~ D(E1,...,Ek), density p_D(x; v1..vk)
  //   branch(B, K1, K2) merge of the two branches of an if, by the guard B
  //   undef             the variable does not exist on that branch
  //   cond(N, x)        K^B_x after the N-th observe(B): equation (1)
  syntax Kernel ::= ker(Set, KBody)
  syntax KBody  ::= delta(Exp)
                  | sample(Dist, Exps)
                  | branch(BExp, KBody, KBody)
                  | "undef"
                  | cond(Int, Id)

  // the probstate and the observation snapshots that cond(N, x) refers to
  syntax Snap ::= snap(Map, List, BExp)   // prior probstate, its order, B

  syntax Set ::= depOf(Kernel)  [function, total]
  rule depOf(ker(D, _)) => D
  syntax KBody ::= bodyOf(Kernel)  [function, total]
  rule bodyOf(ker(_, B)) => B

  syntax Kernel ::= kernelOf(Map, Id)  [function]
  rule kernelOf(X |-> K:Kernel _:Map, X) => K

  // ---- free variables, i.e. dependency sets of [[E]]p and [[B]]p --------
  syntax Set ::= varsE(Exp)  [function, total]
  rule varsE(_:Int) => .Set
  rule varsE(_:Float) => .Set
  rule varsE(X:Id) => SetItem(X)
  rule varsE(ReLU(E)) => varsE(E)
  rule varsE(- E) => varsE(E)
  rule varsE(E1 * E2) => varsE(E1) |Set varsE(E2)
  rule varsE(E1 / E2) => varsE(E1) |Set varsE(E2)
  rule varsE(E1 + E2) => varsE(E1) |Set varsE(E2)
  rule varsE(E1 - E2) => varsE(E1) |Set varsE(E2)

  syntax Set ::= varsEs(Exps)  [function, total]
  rule varsEs(.Exps) => .Set
  rule varsEs(E, Es) => varsE(E) |Set varsEs(Es)

  syntax Set ::= varsB(BExp)  [function, total]
  rule varsB(true) => .Set
  rule varsB(false) => .Set
  rule varsB(E1 == E2) => varsE(E1) |Set varsE(E2)
  rule varsB(E1 != E2) => varsE(E1) |Set varsE(E2)
  rule varsB(E1 < E2)  => varsE(E1) |Set varsE(E2)
  rule varsB(E1 <= E2) => varsE(E1) |Set varsE(E2)
  rule varsB(E1 > E2)  => varsE(E1) |Set varsE(E2)
  rule varsB(E1 >= E2) => varsE(E1) |Set varsE(E2)
  rule varsB(! B) => varsB(B)
  rule varsB(B1 && B2) => varsB(B1) |Set varsB(B2)
  rule varsB(B1 || B2) => varsB(B1) |Set varsB(B2)

  // ---- the introduction order of the variables -------------------------
  // Variables are appended to <order> when they are introduced.  By the
  // paper's assumption every kernel only depends on variables introduced
  // before, so <order> is a topological ordering of G_sigma_p (Lemma 1).
  syntax Set ::= before(Id, List)  [function, total]
  rule before(_, .List) => .Set
  rule before(X, ListItem(X) _) => .Set
  rule before(X, ListItem(Y) L) => SetItem(Y) before(X, L)  requires X =/=K Y

  // every kernel only depends on variables that come earlier in the order
  syntax Bool ::= orderOK(Map, List, List)  [function]
  rule orderOK(_, _, .List) => true
  rule orderOK(S, O, ListItem(X) L)
    => (depOf(kernelOf(S, X)) <=Set before(X, O)) andBool orderOK(S, O, L)
  syntax List ::= set2list(Set)  [function, total]
  rule set2list(.Set) => .List
  rule set2list(SetItem(X) S) => ListItem(X) set2list(S)

  // ---- merging the probstates of the two branches of an if -------------
  syntax Map ::= mergeAll(BExp, Map, Map, List)  [function]
  rule mergeAll(_, _, _, .List) => .Map
  rule mergeAll(B, S1, S2, ListItem(X) L)
    => X |-> merge(B, lookupK(S1, X), lookupK(S2, X)) mergeAll(B, S1, S2, L)

  syntax Kernel ::= lookupK(Map, Id)  [function, total]
  rule lookupK(S, X) => kernelOf(S, X)  requires X in_keys(S)
  rule lookupK(S, X) => ker(.Set, undef)  requires notBool (X in_keys(S))

  // If both branches leave the same kernel, the guard does not influence x,
  // so it is not a direct dependency (Definition 3.2) and the kernel is kept.
  syntax Kernel ::= merge(BExp, Kernel, Kernel)  [function, total]
  rule merge(_, K, K) => K
  rule merge(B, ker(D1, B1), ker(D2, B2))
    => ker(varsB(B) |Set D1 |Set D2, branch(B, B1, B2))
    requires ker(D1, B1) =/=K ker(D2, B2)

  // topological ordering of the variables introduced inside the branches
  syntax List ::= topo(Map, Set, Set)  [function]   // state, todo, placed
  rule topo(_, .Set, _) => .List
  rule topo(S, SetItem(X) Todo, Placed)
    => ListItem(X) topo(S, Todo, Placed SetItem(X))
    requires depOf(kernelOf(S, X)) <=Set Placed
  // if no variable can be placed, topo stays unevaluated (cycle)

  syntax Set ::= list2set(List)  [function, total]
  rule list2set(.List) => .Set
  rule list2set(ListItem(X) L) => SetItem(X) list2set(L)

  // ---- observe: K^B_i for every x_i, in topological order --------------
  // dep(K^B_i) = {x_1, ..., x_{i-1}}
  syntax Map ::= condAll(Int, List, List)  [function]
  rule condAll(_, _, .List) => .Map
  rule condAll(N, O, ListItem(X) L)
    => X |-> ker(before(X, O), cond(N, X)) condAll(N, O, L)
endmodule


// ===========================================================================
// Numeric queries: composing the kernels (Theorem 1) by grid integration
// ===========================================================================
module PPL-NUMERIC
  imports PPL-KERNELS
  imports FLOAT

  // a query function: the value of an expression, or the indicator of B
  syntax QFun ::= fexp(Exp) | find(BExp)

  syntax Float ::= i2f(Int)  [function, total]
  rule i2f(I) => Int2Float(I, 53, 11)

  // ---- evaluation under a (deterministic) valuation sigma : X -> R -----
  syntax Float ::= evalE(Exp, Map)  [function]
  rule evalE(I:Int, _) => i2f(I)
  rule evalE(F:Float, _) => F
  rule evalE(X:Id, V) => {V[X]}:>Float
  rule evalE(ReLU(E), V) => maxFloat(0.0, evalE(E, V))
  rule evalE(- E, V) => --Float evalE(E, V)
  rule evalE(E1 * E2, V) => evalE(E1, V) *Float evalE(E2, V)
  rule evalE(E1 / E2, V) => evalE(E1, V) /Float evalE(E2, V)
  rule evalE(E1 + E2, V) => evalE(E1, V) +Float evalE(E2, V)
  rule evalE(E1 - E2, V) => evalE(E1, V) -Float evalE(E2, V)

  syntax List ::= evalEs(Exps, Map)  [function]
  rule evalEs(.Exps, _) => .List
  rule evalEs(E, Es, V) => ListItem(evalE(E, V)) evalEs(Es, V)

  syntax Bool ::= evalB(BExp, Map)  [function]
  rule evalB(true, _) => true
  rule evalB(false, _) => false
  rule evalB(E1 == E2, V) => evalE(E1, V) ==Float evalE(E2, V)
  rule evalB(E1 != E2, V) => notBool (evalE(E1, V) ==Float evalE(E2, V))
  rule evalB(E1 < E2, V)  => evalE(E1, V) <Float evalE(E2, V)
  rule evalB(E1 <= E2, V) => evalE(E1, V) <=Float evalE(E2, V)
  rule evalB(E1 > E2, V)  => evalE(E1, V) >Float evalE(E2, V)
  rule evalB(E1 >= E2, V) => evalE(E1, V) >=Float evalE(E2, V)
  rule evalB(! B, V) => notBool evalB(B, V)
  rule evalB(B1 && B2, V) => evalB(B1, V) andBool evalB(B2, V)
  rule evalB(B1 || B2, V) => evalB(B1, V) orBool evalB(B2, V)

  syntax Float ::= evalF(QFun, Map)  [function]
  rule evalF(fexp(E), V) => evalE(E, V)
  rule evalF(find(B), V) => 1.0  requires evalB(B, V)
  rule evalF(find(B), V) => 0.0  requires notBool evalB(B, V)

  syntax Set ::= varsF(QFun)  [function, total]
  rule varsF(fexp(E)) => varsE(E)
  rule varsF(find(B)) => varsB(B)

  // ---- E[F | V] under the joint measure induced by a probstate ---------
  // expect(Snaps, State, Order, V, F, N): integrate, in topological order,
  // the variables F needs (its ancestors in the dependency graph) that are
  // not already fixed by the valuation V.  Variables that F does not depend
  // on integrate to 1 and are skipped.
  syntax Float ::= expect(Map, Map, List, Map, QFun, Int)  [function]
  rule expect(Sn, S, O, V, F, N)
    => integ(Sn, S, select(O, anc(S, varsF(F), .Set) -Set keys(V)), V, F, N)

  // ancestors of a set of variables (including themselves)
  syntax Set ::= anc(Map, Set, Set)  [function, total]   // state, todo, done
  rule anc(_, .Set, Done) => Done
  rule anc(S, SetItem(X) Todo, Done) => anc(S, Todo, Done)
    requires X in Done
  rule anc(S, SetItem(X) Todo, Done)
    => anc(S, Todo |Set (depOf(lookupK(S, X)) -Set Done), Done SetItem(X))
    requires notBool (X in Done)

  syntax List ::= select(List, Set)  [function, total]
  rule select(.List, _) => .List
  rule select(ListItem(X) L, Xs) => ListItem(X) select(L, Xs)  requires X in Xs
  rule select(ListItem(X) L, Xs) => select(L, Xs)  requires notBool (X in Xs)

  syntax Float ::= integ(Map, Map, List, Map, QFun, Int)  [function]
  rule integ(_, _, .List, V, F, _) => evalF(F, V)
  rule integ(Sn, S, ListItem(X) Xs, V, F, N)
    => sumPts(Sn, S, points(Sn, S, bodyOf(kernelOf(S, X)), V, N), X, Xs, V, F, N)

  syntax Float ::= sumPts(Map, Map, List, Id, List, Map, QFun, Int)  [function]
  rule sumPts(_, _, .List, _, _, _, _, _) => 0.0
  rule sumPts(Sn, S, ListItem(pt(_, W)) Ps, X, Xs, V, F, N)
    => sumPts(Sn, S, Ps, X, Xs, V, F, N)
    requires W ==Float 0.0
  rule sumPts(Sn, S, ListItem(pt(T, W)) Ps, X, Xs, V, F, N)
    => W *Float integ(Sn, S, Xs, V[X <- T], F, N)
       +Float sumPts(Sn, S, Ps, X, Xs, V, F, N)
    requires W =/=Float 0.0

  // ---- a kernel at a valuation = a list of weighted points -------------
  // points(Snaps, State, Body, V, N) approximates the probability measure
  // K(V, .) by finitely many points pt(value, weight) with weights summing
  // to 1.
  syntax Pt ::= pt(Float, Float)
  syntax List ::= points(Map, Map, KBody, Map, Int)  [function]

  // Dirac kernel: one point
  rule points(_, _, delta(E), V, _) => ListItem(pt(evalE(E, V), 1.0))

  // sampling kernel: N grid points weighted by the density
  rule points(_, _, sample(D, Es), V, N)
    => normalize(gridOf(D, evalEs(Es, V), N))

  // if-merge: the guard is evaluated under the same valuation
  rule points(Sn, S, branch(B, K1, _), V, N) => points(Sn, S, K1, V, N)
    requires evalB(B, V)
  rule points(Sn, S, branch(B, _, K2), V, N) => points(Sn, S, K2, V, N)
    requires notBool evalB(B, V)
  // (undef has no points: querying a variable that does not exist on the
  //  branch taken gets stuck)

  // posterior kernel, equation (1):
  //   K^B_i(v<i, dv_i) = P(B | x<=i = v<=i) / P(B | x<i = v<i) K_i(v_Yi, dv_i)
  // Each point of the prior kernel K_i is reweighted by P(B | x<=i = v<=i)
  // (marginalizing x_{i+1..m} with the prior kernels); normalizing divides
  // by their sum, which is P(B | x<i = v<i).  P(B | x<i = v<i) must be > 0.
  rule points(Sn, _, cond(I, X), V, N)
    => normalize(reweight(Sn, {Sn[I]}:>Snap, X,
         points(Sn, priorOf({Sn[I]}:>Snap), bodyOf(kernelOf(priorOf({Sn[I]}:>Snap), X)), V, N),
         V, N))

  syntax Map ::= priorOf(Snap)  [function, total]
  rule priorOf(snap(S, _, _)) => S

  syntax List ::= reweight(Map, Snap, Id, List, Map, Int)  [function]
  rule reweight(_, _, _, .List, _, _) => .List
  // a point of weight 0 stays 0; its conditional kernel (which may be
  // undefined there, e.g. P(B | ...) = 0) is never needed
  rule reweight(Sn, snap(S, O, B), X, ListItem(pt(T, W)) Ps, V, N)
    => ListItem(pt(T, 0.0)) reweight(Sn, snap(S, O, B), X, Ps, V, N)
    requires W ==Float 0.0
  rule reweight(Sn, snap(S, O, B), X, ListItem(pt(T, W)) Ps, V, N)
    => ListItem(pt(T, W *Float expect(Sn, S, O, V[X <- T], find(B), N)))
       reweight(Sn, snap(S, O, B), X, Ps, V, N)
    requires W =/=Float 0.0

  syntax Float ::= total(List)  [function]
  rule total(.List) => 0.0
  rule total(ListItem(pt(_, W)) Ps) => W +Float total(Ps)

  syntax List ::= scale(List, Float)  [function]
  rule scale(.List, _) => .List
  rule scale(ListItem(pt(T, W)) Ps, C) => ListItem(pt(T, W *Float C)) scale(Ps, C)

  // normalizing a zero measure is undefined (e.g. P(B | x<i = v<i) = 0):
  // normalize stays unevaluated and the query gets stuck
  syntax List ::= normalize(List)  [function]
  rule normalize(Ps) => scale(Ps, 1.0 /Float total(Ps))  requires total(Ps) >Float 0.0

  // ---- continuous distributions ----------------------------------------
  // Parameterizations (the paper does not fix them):
  //   Normal(mu, variance)      Uniform(a, b)       Laplace(mu, b)
  //   Logistic(mu, s)           Exponential(rate)   Gamma(shape k, scale theta)
  //   Pareto(scale x_m, shape alpha)                Student-t(nu)
  // gridOf(D, params, N): N midpoints of a (truncated) support interval, each
  // weighted by the density.  Densities are only needed up to a constant
  // factor, since the points are normalized.
  syntax List ::= gridOf(Dist, List, Int)  [function]
  rule gridOf(D, Ps, N) => gridPts(D, Ps, lo(D, Ps), (hi(D, Ps) -Float lo(D, Ps)) /Float i2f(N), 0, N)
    requires valid(D, Ps) andBool D =/=K Pareto
  // Pareto's heavy tail needs a log-spaced grid: t = x_m e^u for u evenly
  // spaced in [0, ln(10^6) / alpha]; the density in u is p(t) * t.
  rule gridOf(Pareto, ListItem(M:Float) ListItem(A:Float), N)
    => logPts(M, A, (logFloat(1000000.0) /Float A) /Float i2f(N), 0, N)
    requires valid(Pareto, ListItem(M) ListItem(A))

  syntax List ::= logPts(Float, Float, Float, Int, Int)  [function]
  rule logPts(_, _, _, J, N) => .List  requires J >=Int N
  rule logPts(M, A, H, J, N)
    => ListItem(pt(M *Float expF((i2f(J) +Float 0.5) *Float H),
                   expF(--Float A *Float (i2f(J) +Float 0.5) *Float H) *Float H))
       logPts(M, A, H, J +Int 1, N)
    requires J <Int N

  syntax List ::= gridPts(Dist, List, Float, Float, Int, Int)  [function]
  rule gridPts(_, _, _, _, J, N) => .List  requires J >=Int N
  rule gridPts(D, Ps, L, H, J, N)
    => ListItem(pt(L +Float (i2f(J) +Float 0.5) *Float H,
                   dens(D, Ps, L +Float (i2f(J) +Float 0.5) *Float H) *Float H))
       gridPts(D, Ps, L, H, J +Int 1, N)
    requires J <Int N

  syntax Bool ::= valid(Dist, List)  [function, total]
  rule valid(Normal,      ListItem(_) ListItem(V:Float))           => V >Float 0.0
  rule valid(Uniform,     ListItem(A:Float) ListItem(B:Float))     => A <Float B
  rule valid(Laplace,     ListItem(_) ListItem(B:Float))           => B >Float 0.0
  rule valid(Logistic,    ListItem(_) ListItem(S:Float))           => S >Float 0.0
  rule valid(Exponential, ListItem(R:Float))                       => R >Float 0.0
  rule valid(Gamma,       ListItem(K:Float) ListItem(T:Float))     => K >Float 0.0 andBool T >Float 0.0
  rule valid(Pareto,      ListItem(M:Float) ListItem(A:Float))     => M >Float 0.0 andBool A >Float 0.0
  rule valid(Student-t,   ListItem(Nu:Float))                      => Nu >Float 0.0
  rule valid(_, _) => false  [owise]

  // exp(A), computed with + and * only.  K's built-in exponential calls
  // MPFR's mpfr_exp, which was observed to loop forever on some arguments
  // inside long computations.  exp(A) = exp(A / 1024)^1024, where
  // exp(A / 1024) (|A / 1024| < 1) is a Taylor polynomial.
  syntax Float ::= expF(Float)  [function]
  rule expF(A) => 0.0  requires A <Float -700.0
  rule expF(A) => square10(taylorExp(A /Float 1024.0, 1.0, 1.0, 1))
    requires A >=Float -700.0

  // sum of R^k / k! for k = 0..20 (Term = R^(K-1) / (K-1)!)
  syntax Float ::= taylorExp(Float, Float, Float, Int)  [function]
  rule taylorExp(_, Sum, _, K) => Sum  requires K >Int 20
  rule taylorExp(R, Sum, Term, K)
    => taylorExp(R, Sum +Float Term *Float R /Float i2f(K), Term *Float R /Float i2f(K), K +Int 1)
    requires K <=Int 20

  syntax Float ::= square10(Float)  [function]
  rule square10(F) => sq(sq(sq(sq(sq(sq(sq(sq(sq(sq(F))))))))))
  syntax Float ::= sq(Float)  [function]
  rule sq(F) => F *Float F

  // X ^ P for X > 0, as exp(P log X)
  syntax Float ::= powF(Float, Float)  [function]
  rule powF(X, P) => expF(P *Float logFloat(X))  requires X >Float 0.0

  syntax Float ::= sqrtF(Float)  [function]
  rule sqrtF(F) => rootFloat(F, 2)

  // truncated supports: the mass outside them is negligible
  // (heavy-tailed Pareto/Student-t: see README)
  syntax Float ::= lo(Dist, List)  [function]
                 | hi(Dist, List)  [function]
  rule lo(Normal,      ListItem(M:Float) ListItem(V:Float)) => M -Float 8.0 *Float sqrtF(V)
  rule hi(Normal,      ListItem(M:Float) ListItem(V:Float)) => M +Float 8.0 *Float sqrtF(V)
  rule lo(Uniform,     ListItem(A:Float) ListItem(_))       => A
  rule hi(Uniform,     ListItem(_) ListItem(B:Float))       => B
  rule lo(Laplace,     ListItem(M:Float) ListItem(B:Float)) => M -Float 30.0 *Float B
  rule hi(Laplace,     ListItem(M:Float) ListItem(B:Float)) => M +Float 30.0 *Float B
  rule lo(Logistic,    ListItem(M:Float) ListItem(S:Float)) => M -Float 35.0 *Float S
  rule hi(Logistic,    ListItem(M:Float) ListItem(S:Float)) => M +Float 35.0 *Float S
  rule lo(Exponential, ListItem(_))                         => 0.0
  rule hi(Exponential, ListItem(R:Float))                   => 30.0 /Float R
  rule lo(Gamma,       ListItem(_) ListItem(_))             => 0.0
  rule hi(Gamma,       ListItem(K:Float) ListItem(T:Float))
    => T *Float (K +Float 10.0 *Float sqrtF(K) +Float 30.0)
  rule lo(Pareto,      ListItem(M:Float) ListItem(_))       => M
  rule hi(Pareto,      ListItem(M:Float) ListItem(A:Float))
    => M *Float powF(1000000.0, 1.0 /Float A)
  rule lo(Student-t,   ListItem(_))                         => -50.0
  rule hi(Student-t,   ListItem(_))                         => 50.0

  // unnormalized densities
  syntax Float ::= dens(Dist, List, Float)  [function]
  rule dens(Normal, ListItem(M:Float) ListItem(V:Float), X)
    => expF(--Float ((X -Float M) *Float (X -Float M)) /Float (2.0 *Float V))
  rule dens(Uniform, _, _) => 1.0
  rule dens(Laplace, ListItem(M:Float) ListItem(B:Float), X)
    => expF(--Float absFloat(X -Float M) /Float B)
  rule dens(Logistic, ListItem(M:Float) ListItem(S:Float), X)
    => expF(--Float (X -Float M) /Float S)
       /Float ((1.0 +Float expF(--Float (X -Float M) /Float S))
               *Float (1.0 +Float expF(--Float (X -Float M) /Float S)))
  rule dens(Exponential, ListItem(R:Float), X) => expF(--Float R *Float X)
  rule dens(Gamma, ListItem(K:Float) ListItem(T:Float), X)
    => powF(X, K -Float 1.0) *Float expF(--Float X /Float T)
  rule dens(Pareto, ListItem(_) ListItem(A:Float), X) => powF(X, --Float (A +Float 1.0))
  rule dens(Student-t, ListItem(Nu:Float), X)
    => powF(1.0 +Float X *Float X /Float Nu, --Float (Nu +Float 1.0) /Float 2.0)
endmodule


// ===========================================================================
// Execution of programs: transformations over probstates (Fig. 2)
// ===========================================================================
module PPL
  imports PPL-NUMERIC

  configuration <T>
                  <k> $PGM:Stmts </k>
                  // sigma_p : X -> K, each variable mapped to ker(dep, body)
                  <pstate> .Map </pstate>
                  // introduction order = a topological ordering of G_sigma_p
                  <order> .List </order>
                  // prior probstates of the observe statements executed
                  <snapshots> .Map </snapshots>
                  <nextSnapshot> 0 </nextSnapshot>
                  // numeric queries
                  <grid> 200 </grid>
                  <results> .List </results>
                </T>

  // a run-time error that stops the execution
  syntax KItem ::= error(String, K)

  // ---- sequencing:  [[P1; P2]]p = [[P2]]p([[P1]]p) ----------------------
  rule S:Stmt Ss:Stmts => S ~> Ss
  rule S:Stmt ; Ss:Stmts => S ~> Ss
  rule S:Stmt ; => S
  syntax KItem ::= runBlock(Block)
  rule runBlock({ }) => .K
  rule runBlock({ Ss }) => Ss

  // ---- skip -------------------------------------------------------------
  rule skip => .K

  // ---- x := E   and   x ~ D(E1,...,Ek) ----------------------------------
  // Both bind x to a kernel whose dependency set is the set of variables of
  // the right-hand side: [[x := E]]p = sigma_p[x |-> [[E]]p], where
  // [[E]]p is the Dirac kernel delta(E) with dep = vars(E).
  rule X:Id := E => #bind(X, ker(varsE(E), delta(E)))
  rule X:Id ~ D:Dist ( Es ) => #bind(X, ker(varsEs(Es), sample(D, Es)))

  // The paper's assumption: the kernel of a variable may only depend on
  // variables introduced BEFORE it.  A new variable is appended to <order>.
  syntax KItem ::= #bind(Id, Kernel)
  rule <k> #bind(_, K) => error("undefined variable(s)", depOf(K) -Set keys(S)) ...</k>
       <pstate> S </pstate>
    requires notBool (depOf(K) <=Set keys(S))
  rule <k> #bind(X, K) => error("assumption violated: self-reference", X) ...</k>
       <pstate> S </pstate>
    requires depOf(K) <=Set keys(S) andBool X in depOf(K)
  rule <k> #bind(X, K) => .K ...</k>
       <pstate> S => S[X <- K] </pstate>
       <order> O => O ListItem(X) </order>
    requires depOf(K) <=Set keys(S) andBool notBool (X in_keys(S))
  rule <k> #bind(X, K) => .K ...</k>
       <pstate> S => S[X <- K] </pstate>
       <order> O </order>
    requires X in_keys(S) andBool notBool (X in depOf(K))
     andBool depOf(K) <=Set before(X, O)
  rule <k> #bind(X, K)
        => error("assumption violated: depends on variable(s) introduced after it",
                 ListItem(X) ListItem(depOf(K) -Set before(X, O))) ...</k>
       <pstate> S </pstate>
       <order> O </order>
    requires X in_keys(S) andBool depOf(K) <=Set keys(S)
     andBool notBool (X in depOf(K))
     andBool notBool (depOf(K) <=Set before(X, O))

  // ---- if B then P1 else P2 ---------------------------------------------
  // Both branches run from the same probstate; the resulting probstates are
  // merged by the guard: K_x = branch(B, K1_x, K2_x) with
  // dep = dep(B) U dep(K1_x) U dep(K2_x).
  syntax KItem ::= #afterThen(BExp, Map, List, Block)
                 | #afterElse(BExp, Map, List, Map, List)
                 | "#checkOrder"
  rule <k> if B then P1 else P2 => runBlock(P1) ~> #afterThen(B, S, O, P2) ...</k>
       <pstate> S </pstate>
       <order> O </order>
    requires varsB(B) <=Set keys(S)
  rule <k> if B then _ else _ => error("undefined variable(s)", varsB(B) -Set keys(S)) ...</k>
       <pstate> S </pstate>
    requires notBool (varsB(B) <=Set keys(S))

  rule <k> #afterThen(B, S0, O0, P2) => runBlock(P2) ~> #afterElse(B, S0, O0, S1, O1) ...</k>
       <pstate> S1 => S0 </pstate>
       <order> O1 => O0 </order>

  rule <k> #afterElse(B, _S0, O0, S1, _O1) => #checkOrder ...</k>
       <pstate> S2 => mergeAll(B, S1, S2, set2list(keys(S1) |Set keys(S2))) </pstate>
       <order> _ => O0 topo(mergeAll(B, S1, S2, set2list(keys(S1) |Set keys(S2))),
                            (keys(S1) |Set keys(S2)) -Set list2set(O0), list2set(O0)) </order>

  rule <k> #checkOrder => .K ...</k>
       <pstate> S </pstate> <order> O </order>
    requires orderOK(S, O, O)
  rule <k> #checkOrder
        => error("assumption violated: after the if, a kernel depends on a variable introduced after it", .K) ...</k>
       <pstate> S </pstate> <order> O </order>
    requires notBool orderOK(S, O, O)

  // ---- while B do P -------------------------------------------------------
  // The paper does not define the semantics of while yet.
  rule while _ do _ => error("while is not supported yet (its semantics is not defined in the paper)", .K)

  // ---- observe(B) ---------------------------------------------------------
  // Every variable x_i (in the topological order x_1..x_m) gets the
  // posterior kernel K^B_i of equation (1), with dep = {x_1..x_{i-1}}.  The
  // prior probstate is saved as snapshot N, which cond(N, x_i) refers to.
  rule <k> observe(B) => .K ...</k>
       <pstate> S => condAll(N, O, O) </pstate>
       <order> O </order>
       <snapshots> Sn => Sn[N <- snap(S, O, B)] </snapshots>
       <nextSnapshot> N => N +Int 1 </nextSnapshot>
    requires varsB(B) <=Set keys(S)
  rule <k> observe(B) => error("undefined variable(s)", varsB(B) -Set keys(S)) ...</k>
       <pstate> S </pstate>
    requires notBool (varsB(B) <=Set keys(S))

  // ---- numeric queries ----------------------------------------------------
  // P(B) and E[E] under the joint measure alpha(sigma_p) induced by the
  // current probstate (Property (1) / Theorem 1).
  syntax Query ::= Pr(BExp) | Ex(Exp)
  syntax Result ::= Query "=" Float
  rule <k> grid N:Int => .K ...</k> <grid> _ => N </grid>  requires N >Int 0

  rule <k> query prob(B) => .K ...</k>
       <pstate> S </pstate> <order> O </order> <snapshots> Sn </snapshots> <grid> N </grid>
       <results>... .List => ListItem(Pr(B) = expect(Sn, S, O, .Map, find(B), N)) </results>
    requires varsB(B) <=Set keys(S)
  rule <k> query mean(E) => .K ...</k>
       <pstate> S </pstate> <order> O </order> <snapshots> Sn </snapshots> <grid> N </grid>
       <results>... .List => ListItem(Ex(E) = expect(Sn, S, O, .Map, fexp(E), N)) </results>
    requires varsE(E) <=Set keys(S)
  rule <k> query prob(B) => error("undefined variable(s)", varsB(B) -Set keys(S)) ...</k>
       <pstate> S </pstate>
    requires notBool (varsB(B) <=Set keys(S))
  rule <k> query mean(E) => error("undefined variable(s)", varsE(E) -Set keys(S)) ...</k>
       <pstate> S </pstate>
    requires notBool (varsE(E) <=Set keys(S))
endmodule
