# A K Interpreter for the Kernel-Based Semantics of Probabilistic Programs

This directory contains an executable K definition of the language and the
**kernel-based concrete semantics** of the paper *Probabilistic Programs
Semantics* (Fig. 1 and Fig. 2).

Running a program computes its final **probabilistic state** (probstate)
`σp`. A probstate maps every program variable `x` to a Markov kernel `K_x`
together with its direct dependency set `dep(K_x)`. The kernels are kept
**symbolically**, exactly as Fig. 2 builds them.

On top of the symbolic semantics, the interpreter answers **numeric queries**
(`P(B)` and `E[e]`) about the joint measure that the probstate induces.
It composes the kernels along a topological order, as in Theorem 1, using
grid integration.

```
project_ppl/
├── ppl.k        the K definition (syntax, kernels, numeric queries, statements)
├── Makefile     make / make test / make update-results / make clean
└── tests/       example programs (*.ppl) and their expected outputs (*.ppl.out)
```

## Running it

You need the K framework (tested with K v7.1.337, LLVM backend).

```sh
make kompile                          # build ppl-kompiled/
krun tests/running-example.ppl        # run one program
make test                             # run all tests and compare with tests/*.out
```

`krun` prints the final configuration:

| cell | content |
|------|---------|
| `<pstate>` | the probstate `σp`: `x \|-> ker(dep(K_x), body)` |
| `<order>` | the variables in order of introduction, which is a topological ordering of the dependency graph `G_σp` |
| `<snapshots>` | the prior probstate and the event `B` of every `observe(B)` executed (used by the posterior kernels) |
| `<results>` | the answers to the `query` statements, e.g. `Pr(z > 1) = 0.2397...` |
| `<k>` | `.K` on success, or `error("...", ...)` when the program is rejected |

## The language (Fig. 1)

```
E ::= c | x | E + E | E - E | E * E | E / E | -E | ReLU(E) | (E)
B ::= true | false | E == E | E != E | E < E | E <= E | E > E | E >= E
    | B && B | B || B | !B | (B)
s ::= skip
    | x := E                       (also written  x = E,  as in Fig. 3)
    | x ~ D(E1, ..., Ek)
    | if B then { P } else { P }
    | while B do { P }             (rejected, see below)
    | observe(B)
P ::= s | s; P                     (the ";" is optional; newlines are enough)
D ::= Normal | Uniform | Laplace | Logistic | Exponential | Gamma | Pareto | Student-t
```

There are a few differences from Fig. 1:
* **Braces:** the branches of `if` (and the body of `while`) are written in
  braces, so that a sequence `s; P` inside a branch is unambiguous.
* **`ReLU`:** it is added, because the paper's running example (Fig. 3) uses it.
* **Constants:** they can be integers (`1`) or decimals (`0.5`, `1e-3`).
* **Spacing:** write `x - 1` with spaces. K reads `x-1` as `x` followed by the
  number `-1`.

The interpreter adds two statements of its own:

```
query prob(B)      append P(B) under the current probstate to <results>
query mean(E)      append E[E] under the current probstate to <results>
grid N             use N grid points per continuous variable (default 200)
```

The paper does not fix the parameterizations of the distributions, so these
are used:

| distribution | parameters | mean |
|---|---|---|
| `Normal(mu, v)` | mean, **variance** (as in the paper: `N(0,2)` has variance 2) | `mu` |
| `Uniform(a, b)` | interval | `(a+b)/2` |
| `Laplace(mu, b)` | location, scale | `mu` |
| `Logistic(mu, s)` | location, scale | `mu` |
| `Exponential(r)` | rate | `1/r` |
| `Gamma(k, t)` | shape, scale | `k t` |
| `Pareto(m, a)` | scale `x_m`, shape `alpha` | `a m / (a-1)` |
| `Student-t(nu)` | degrees of freedom | `0` |

## How Fig. 2 is implemented

### Kernels

A kernel is the term `ker(Dep, Body)`, where `Dep` is `dep(K)` and `Body` is
one of:

| body | meaning | created by |
|---|---|---|
| `delta(E)` | Dirac kernel `[[E]]p`: concentrated at the value of `E` | `x := E` |
| `sample(D, E1..Ek)` | kernel with density `p_D(x; v1..vk)` | `x ~ D(E1..Ek)` |
| `branch(B, K1, K2)` | `K1` where the guard event `[[B]]p` holds, `K2` elsewhere | `if` |
| `undef` | the variable does not exist on that branch | `if` |
| `cond(N, x)` | the posterior kernel `K^B_x` of equation (1), for the `N`-th observe | `observe` |

Expressions and Boolean expressions are kept as syntax. Their dependency
sets are their free variables (`varsE`, `varsB`), as in the rules for
`[[c]]p`, `[[x]]p`, `[[E1 op E2]]p` and `[[E1 cmp E2]]p`.

### Statements

* **`skip`:** leaves `σp` unchanged.
* **`x := E`:** `σp[x ↦ ker(vars(E), delta(E))]`.
* **`x ~ D(E1..Ek)`:** `σp[x ↦ ker(vars(E1) ∪ … ∪ vars(Ek), sample(D, E1..Ek))]`.
* **`P1; P2`:** runs `P1`, then `P2` on the resulting probstate.
* **`if B then {P1} else {P2}`:** runs both branches from the same `σp`, then
  merges the two results. Every variable in `dom(σ1) ∪ dom(σ2)` gets
  `ker(dep(B) ∪ dep(K1) ∪ dep(K2), branch(B, K1, K2))`. If both branches
  leave a variable with the **same** kernel, that kernel is kept unchanged:
  the guard does not influence the variable, so by Definition 3.2 it is not
  a direct dependency.
* **`observe(B)`:** saves the prior probstate as snapshot `N`. Then, for the
  topological order `x1..xm` in `<order>`, every `x_i` gets
  `ker({x1..x_{i-1}}, cond(N, x_i))`. This is exactly the dependency set
  `dep(K^B_i)` of Fig. 2.

For the running example (Fig. 3, `tests/running-example.ppl`), the final
probstate is:

```
x |-> ker ( .Set , cond ( 0 , x ) )
y |-> ker ( SetItem ( x ) , cond ( 0 , y ) )
z |-> ker ( SetItem ( x ) SetItem ( y ) , cond ( 0 , z ) )
```

Snapshot 0 is the prior probstate:
`x ↦ Normal(0,1)`, `y ↦ Normal(x,1)` with dep `{x}`, `z ↦ delta(ReLU(y))`
with dep `{y}`, together with the event `z > 1`. This is the result traced in
§3.3 of the paper.

And for `tests/if-merge.ppl`:

```
w |-> ker ( .Set , delta ( 7 ) )
x |-> ker ( .Set , sample ( Uniform , 0 , 1 , .Exps ) )
y |-> ker ( SetItem ( x ) , branch ( x < 0.5 , delta ( 0 ) , sample ( Normal , x , 1 , .Exps ) ) )
```

### The paper's assumption

> whenever a new variable `x_i` is introduced, the kernel associated with
> `x_i` may depend only on variables that have already been introduced

Variables are recorded in `<order>` when they are introduced. Every new
kernel for a variable `x` may only depend on variables that come **before**
`x` in that order. This guarantees that the dependency graph is acyclic
(Lemma 1). If a program breaks the assumption, it is rejected: execution
stops with an `error(...)` term in `<k>`. The cases are:

* **Self-reference:** `x := x + 1` (`tests/error-self-reference.ppl`).
* **A later variable:** `x ~ …; y ~ Normal(x,1); x := y`
  (`tests/error-later-variable.ppl`).
* **After an `if`:** a kernel that now depends on a later variable, because
  the merged kernel also depends on the guard
  (`tests/error-if-later-variable.ppl`).
* **Undefined variable:** using a variable that was never defined.

The variables introduced inside the two branches of an `if` are added to
`<order>` in topological order of their merged kernels.

### `while`

Fig. 2 does not define `while` yet, so `while B do { P }` stops with
`error("while is not supported yet ...")` (`tests/error-while.ppl`).

## Numeric queries

`query prob(B)` and `query mean(E)` evaluate `P(B)` and `E[E]` under the
joint measure `α(σp)` induced by the current probstate (Property (1)).

* **Order of integration:** following Theorem 1, the variables are integrated
  one after another in the topological order `<order>`.
* **Skipped variables:** only the variables the query needs (the ancestors of
  its variables in the dependency graph) are integrated. All other kernels
  integrate to 1.
* **Weighted points:** at a given valuation of its dependencies, each kernel
  becomes a list of weighted points whose weights sum to 1:
  * **`delta(E)`:** one point, the value of `E`.
  * **`sample(D, …)`:** `N` evenly spaced midpoints on the support of `D`,
    weighted by the density. Infinite supports are truncated (Normal: mean ±
    8 standard deviations; Exponential: up to 30/rate; and so on). Pareto
    uses a log-spaced grid because of its heavy tail. Densities are only
    needed up to a constant factor, because the weights are normalized.
  * **`branch(B, K1, K2)`:** evaluates the guard at the current valuation,
    then uses `K1` or `K2`.
  * **`cond(N, x_i)`:** this is equation (1). Each point `v_i` of the prior
    kernel `K_i` is reweighted by `P(B | x≤i = v≤i)`, computed by integrating
    the remaining variables with the **prior** kernels of snapshot `N`.
    Normalizing then divides by the sum of the new weights, which is
    `P(B | x<i = v<i)`. A point whose prior weight is 0 stays 0 (its
    posterior kernel is never needed).

The results are approximate. Expectations of smooth functions are very
accurate. Probabilities of events converge more slowly, because the
indicator function jumps (the error is about the grid spacing). Use `grid N`
to change the resolution. Results of the tests (default `grid 200` unless
stated):

| test | query | interpreter | exact |
|---|---|---|---|
| running-example | `P(z > 1)` before observe | 0.239721 | `1-Φ(1/√2)` = 0.239750 |
| running-example | `E[x]` after `observe(z > 1)` | 0.916526 | 0.916356 |
| running-example | `P(z > 1)` after observe | 1.000000 | 1 |
| property3-a / -b | `E[x*y]`, `E[y*y]` | 1.000000, 2.000000 (both) | 1, 2 |
| property3-a / -b | `P(x + y > 1)` | 0.3243 / 0.3290 | `1-Φ(1/√5)` = 0.3274 |
| if-merge | `E[y]`, `P(y == 0)` | 0.375000, 0.500000 | 0.375, 0.5 |
| two-observes (`grid 100`) | `E[x]` after the 1st / 2nd observe | 0.6683 / 0.8350 | 2/3 / 5/6 |
| distributions | means of all 8 distributions | within 0.3% (Exponential, Gamma, Pareto) or better | see table above |

`property3-a.ppl` and `property3-b.ppl` are the two probstates of Property
(3). Their kernels and dependency graphs differ (`x → y` vs `y → x`), but
they induce the same joint measure, so the queries agree up to grid error.

**Implementation note.** The exponential and power functions are computed
by the definition itself (`expF`, `powF`: range reduction plus a Taylor
series) instead of K's built-in `expFloat`/`^Float`. The built-in versions
call MPFR's `mpfr_exp`, which was observed to loop forever on some arguments
during long computations. The hang depended on the grid size: `grid 199`
hung where `grid 200` did not.

## Observations about the semantics

These are things the interpreter makes visible. They may be worth
considering for the paper.

1. **Kernels refer to variables by name.** `[[x := E]]p = σp[x ↦ [[E]]p]`
   stores a kernel over the *current* variables of `E`. Reassigning one of
   them later is allowed by the assumption, but it changes the joint measure
   seen through the earlier variables. In `tests/reassign-by-name.ppl`:

   ```
   x ~ Normal(0, 1)
   y := x + 1          E[y] = 1
   x := 3              E[y] = 4
   ```

   In an ordinary sampling execution, `y` would keep mean 1.
2. **"The dependency remains unchanged thereafter" does not hold.** The
   assumption says the dependency set of a variable never changes after it
   is introduced. But `if` (`dep(B) ∪ dep(K1) ∪ dep(K2)`) and `observe`
   (`{x1..x_{i-1}}`) both change dependency sets. The interpreter therefore
   enforces only the first half of the assumption (dependencies on earlier
   variables only), which is what the proof of Lemma 1 uses.
3. **`if` can break acyclicity.** Branching on a variable introduced after
   `x` and assigning `x` in a branch makes `x` depend on a later variable.
   The interpreter rejects such programs (`tests/error-if-later-variable.ppl`).
4. **Dependency sets are computed from the syntax.** They are the free
   variables of the expressions, which can be larger than the minimal set of
   Definition 3.2 in degenerate cases such as `x - x`.
5. **`P(B | x<i = v<i)` can be 0 on part of the space.** For example, after
   `observe(x + y > 1)` with `x, y ~ Uniform(0,1)`, it is 0 at `x = 0`.
   There `K^B_i` is undefined. This does not matter for the joint measure,
   because that region has prior probability 0, and the numeric evaluation
   skips such points.
