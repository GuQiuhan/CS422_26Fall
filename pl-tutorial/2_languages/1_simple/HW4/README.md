# CS422 HW4: SIMPLE

Each exercise has its own directory. Each directory contains the modified
definition (a copy of the tutorial's literate `.md` file, with every change
marked `HW4 Exercise N`), a `Makefile`, and the exercise's tests from
`pl-tutorial/2_languages/1_simple`. Run `make` in a directory to kompile the
definition and run its tests.

My own test programs are in `tests/hw4/` in each directory:
`hw4-succeed.simple` should succeed and `hw4-fail.simple` should fail.

| Dir | Exercise | Base definition |
|-----|----------|-----------------|
| `ex1/` | `break;` and `continue;` | untyped SIMPLE (`simple-untyped.md`) |
| `ex2/` | typed exceptions, dynamic semantics | `simple-typed-dynamic.md` |
| `ex3/` | typed exceptions and `throws`, static semantics | `simple-typed-static.md` |
| `ex4/` | no duplicate declarations in a block, static semantics | `simple-typed-static.md` |

---

## Exercise 1: `break;` and `continue;`

`break` and `continue` are added to the **syntax** module, so the program
parser knows them. Otherwise `break;` would parse as an expression statement
that looks up a variable called `break`.

```k
                | "break" ";"
                | "continue" ";"
```

**Do we still want to desugar `for` into `while`? No.** The old macro turns
`for(Start Cond; Step) {S}` into `{Start while(Cond) {S Step;}}`. A
`continue` inside `S` would then jump over `Step` and skip the increment, so
a loop like `for(var i=0; i<=5; ++i) {... continue; ...}` would never end.
Both loops therefore become one internal construct that knows its step
statement:

```k
  syntax Stmt ::= loop(Exp, Stmt, Block)       // condition, step, body
                | iterate(Exp, Stmt, Block)
  rule while (E) S => loop(E, {}, S)
  rule for(Start Cond; Step) S => {Start loop(Cond, Step;, S)}
```

A new cell `<lstack>` inside `<control>` holds one frame per active loop.
It works like `<xstack>` does for exceptions:

```k
  syntax KItem ::= lframe(Exp, Stmt, Block, K, Map, ControlCellFragment) | "popl"

  rule <k> (loop(E, St, S) => iterate(E, St, S) ~> popl) ~> K </k>
       <control> <lstack> .List => ListItem(lframe(E, St, S, K, Env, C)) ...</lstack> C </control>
       <env> Env </env>

  rule iterate(E, St, S) => if (E) {S St iterate(E, St, S)}
  rule <k> popl => .K ...</k> <lstack> ListItem(_) => .List ...</lstack>

  rule <k> break; ~> _ => K </k>
       <control> <lstack> ListItem(lframe(_,_,_,K,Env,C)) => .List ...</lstack> (_ => C) </control>
       <env> _ => Env </env>

  rule <k> continue; ~> _ => St ~> iterate(E, St, S) ~> popl ~> K </k>
       <control> <lstack> ListItem(lframe(E,St,S,K,Env,C)) ...</lstack> (_ => C) </control>
       <env> _ => Env </env>
```

A frame stores the computation `K` after the loop, the environment `Env` at
loop entry, and `C`, the rest of the control cell (the function and
exception stacks).

* **`break;`** pops the frame, restores `Env` and `C`, and continues with `K`.
* **`continue;`** keeps the frame, restores `Env` and `C`, runs the step,
  and starts the next iteration.
* **A normal exit** from the loop runs `popl`, which pops the frame.

Restoring `C` matters. If a `try` block is entered inside the loop body and
the body then does `break` or `continue`, that `try`'s handler has to be
discarded. Otherwise a later `throw` would be caught by a stale handler.
Restoring `Env` throws away variables declared in the body. For example, in
`while-with-locals`, `j` prints 0.

The provided test `break-from-function` documents the expected behaviour
that a `break` inside a called function leaves the caller's loop
("wrongly succeeding"). This definition behaves the same way, because the
loop stack is not emptied on function calls.

**My tests:**
* **`hw4-succeed`:** `continue` in a `for` loop must still run `++i`. A
  `break`/`continue` taken from inside a `try` in the loop body must drop
  that handler, so the later `throw 42` is caught by the **outer** handler.
  `continue` must also restore the environment, so `while (++n <= 3)` uses
  the outer `n`, not the `var n = 100` declared in the body. Output:
  `i = 1`, `i = 3`, `outer handler caught 42`, `100 100 100 n = 4`.
* **`hw4-fail`:** a `break;` outside of any loop. The execution gets stuck
  with `break ;` on top of `<k>`, after printing only `before`.

## Exercise 2: typed exceptions (dynamic semantics)

The innermost handler catches a value only if the value's type equals the
handler's parameter type. Otherwise the handler is popped and the same value
is thrown again, so it moves out to the next enclosing `try`-`catch`:

```k
  rule <k> throw V:Val; ~> _ => { T X = V; S2 } ~> K </k>
       <control>
         <xstack> ListItem((T:Type X:Id, S2, K, Env, C)) => .List ...</xstack>
         (_ => C)
       </control>
       <env> _ => Env </env>
    requires typeOf(V) ==K T

  rule <k> throw V:Val; ...</k>
       <xstack> ListItem((T:Type _:Id, _:Stmt, _:K, _:Map, _:ControlCellFragment)) => .List ...</xstack>
    requires typeOf(V) =/=K T
```

The handler that finally catches the value restores its own environment and
control cell (function stack, return type), so propagation across function
calls works too. If no handler has the right type, execution gets stuck with
an uncaught `throw` on top of `<k>`. For example,
`try { try { throw 7; } catch(bool x) {print(1);} } catch(int x) {print(2);}`
prints `2`.

**My tests:**
* **`hw4-succeed`:** a string is thrown at depth 0 inside the recursive
  `int f(int)`. Every frame of `f` has an `int` handler, and none of them may
  catch it. The string handler in `string g()` catches it and runs
  `return prefix + s;`. This works only if `g`'s environment and `g`'s
  return type (`string`) were restored, not `f`'s. Output: `caught deep`.
* **`hw4-fail`:** `throw true;` inside handlers for `int` and for `string`.
  No handler matches, so the execution gets stuck with `throw true ;` on top
  of `<k>`, after printing only `before`.

## Exercise 3: typed exceptions and `throws` (static semantics)

**Syntax.** Functions may declare the exceptions they throw, and function
types can record them, so that functions passed as values keep this
information:

```k
  syntax Type ::= ... > Types "->" Type
                      | Types "->" Type "throws" Types
  syntax Stmt ::= ... | Type Id "(" Params ")" "throws" Types Block
```

For example, `int foo(int x) throws bool {...}` has type
`int -> int throws bool`. A type written without `throws` throws nothing, so
`int->int` and `int->int throws bool` are different types.

**Semantics.** Each local task has a new cell `<allowed>`. It holds the set
of exception types that may be thrown at the current point, either because
an enclosing `try`-`catch` catches them or because the function declares
them:

* **Function body:** `<allowed>` starts as the function's `throws` set, or
  `.Set` if the function has no `throws` clause. The task that checks
  `main()` and spawned threads also start with `.Set`, so nothing may escape
  to the top level.
* **`try S1 catch(T X) S2`:** `S1` is checked in a new task whose
  `<allowed>` also contains `T`. The handler `{T X; S2}` is checked with the
  outer `<allowed>`, because an exception thrown inside a handler goes
  outward. This replaces the old rule, which accepted only `int` handlers.
* **`throw` of type `T`:** accepted only if `T` is in `<allowed>`. Otherwise
  the exception could escape uncaught, and type checking gets stuck.
* **Calling `Ts -> T throws Es`:** accepted only if every type in `Es` is in
  `<allowed>`.
* **Blocks:** they copy the cell, as they already did for `<returnType>`.

```k
  rule <task> <k> try S1 catch(T:Type X:Id) S2 => {T X; S2} ...</k>
         <tenv> Rho </tenv> <allowed> A </allowed> R </task>
       (.Bag => <task> <k> S1 </k> <tenv> Rho </tenv> <allowed> A SetItem(T) </allowed> R </task>)
  rule <k> throw T:Type; => stmt ...</k> <allowed>... SetItem(T) ...</allowed>
  rule <k> (Ts:Types -> T throws Es)(Ts) => T ...</k> <allowed> A </allowed>
    requires Ts =/=K .Types andBool allIn(Es, A)
```

As the expected outputs require, `exceptions_02` and `exceptions_09` are
now rejected: they throw out of a function that has no `throws` clause.

**My tests:**
* **`hw4-succeed`:** a function type with a two-element `throws` clause is
  used as a **parameter type**
  (`int apply(int->int throws string, bool g, int v) throws bool`). Calling
  `g` inside `try ... catch(string s)` is accepted because `bool` comes from
  `apply`'s own `throws`. The catch block throws a new `bool`, which only the
  outer context (`apply`'s `throws`, then `main`'s `catch(bool b)`) handles.
  Result: `#Top`.
* **`hw4-fail`:** `try { throw 1; } catch(int x) { throw x + 1; }` in
  `main`. A handler does not protect itself, so the second `int` would
  escape. It must be rejected: `#Bottom`. A definition that checks the
  handler with the try's extended set would wrongly accept it.

## Exercise 4: no duplicate declarations in a block (static semantics)

In the static semantics every block is type checked in its own task, so
"the current block" is simply "the current task". Each local task gets a new
cell `<decls>` holding the variables declared so far in that block:

```k
  rule <k> T:Type X:Id; => stmt ...</k> <tenv> Rho => Rho[X <- T] </tenv>
       <decls> D => D SetItem(X) </decls>
    requires notBool (X in D)                 // the second declaration gets stuck

  rule <task> <k> {S} => block ...</k> <tenv> Rho </tenv> <decls> _ </decls> R </task>
       (.Bag => <task> <k> S </k> <tenv> Rho </tenv> <decls> .Set </decls> R </task>)

  rule try block catch(int X:Id) S => {int X; S}   // S is a block: a new scope
```

* **New blocks:** they start with an empty `<decls>`. Function tasks, the
  `main()` task and spawned threads also start empty.
* **Function parameters:** they are declared in the function's task, but the
  body is a separate block, so the body may redeclare a parameter.
* **The catch parameter:** the old rule spliced the parameter into the
  handler block (`{int X; S'}`), which would make `catch(int x) { int x; }`
  a duplicate. The new rule wraps the whole block `S`, so the parameter is
  outside it, as the exercise requires.
* **Arrays:** `int x[10];` desugars into a declaration of `x`, so array and
  scalar variables share one name space (test `ex08`).
* **Globals:** they were already checked against `<gtenv>`.

**My tests:**
* **`hw4-succeed`:** it redeclares names in every legal way. A parameter is
  redeclared in the body. A `for` loop variable `i` is redeclared after the
  loop, which is allowed because the `for` creates its own block. A name is
  declared in a sibling inner block and then again in the outer block. A
  global is shadowed. A catch parameter is redeclared in its handler. A
  variable is declared inside the `try` block. Result: `#Top`.
* **`hw4-fail`:** `{ int a = 1; } int a = 2, b = 3, a = 4;`. The duplicate
  is hidden in a multi-variable declaration, which desugars into separate
  declarations, after an inner block that also declares `a`. Result:
  `#Bottom`.

---

## Test results

These were run with K v7.1.337. All provided exercise tests and all my
tests give the expected results.

The only remaining difference is `tests/threads/threads_05.simple` in Ex1
and Ex2. It prints the whole final configuration, and this K version prints
`.` as `.K`. In Ex1, the old reference output also shows its loop rewritten
as `for (...)` where my definition keeps the program's `while`. After
normalizing those two printing details, the output is identical. That test
must be run with stdin closed (`< /dev/null`), as `make` does, because
SIMPLE reads from stdin.
