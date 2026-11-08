# CS422 HW5: private members in KOOL

Each exercise has its own directory. Each directory contains:

* the modified definition, as a `.k` file. The code is extracted from the
  tutorial's literate `.md` file, and every change is marked `HW5 Exercise N`;
* a `Makefile`;
* the tests of the `private-members` exercise from the tutorial. These are
  the original KOOL test programs plus `ex01`–`ex22`.

Run `make` in a directory to kompile the definition and run its tests.

| Dir | Exercise | Base definition |
|-----|----------|-----------------|
| `ex1/` | private members, untyped KOOL | `1_untyped/kool-untyped.md` |
| `ex2/` | private members, dynamically typed KOOL | `2_typed/1_dynamic/kool-typed-dynamic.md` |
| `ex3/` | private members, statically typed KOOL | `2_typed/2_static/kool-typed-static.md` |

The syntax change is the same in all three. `private` may come before a
field or method declaration:

```k
  | "private" "var" Exps ";"                     // untyped
  | "private" "method" Id "(" Ids ")" Block
  | "private" Type Exps ";"                      // typed
  | "private" Type Id "(" Params ")" Block
```

As for ordinary declarations, `private var x = 1, y = 2;` is desugared into
`private var x; x = 1; private var y; y = 2;`.

---

## Exercise 1: untyped KOOL

A private member may be accessed only from code of the class that declares
it. Access from another object of the same class is allowed. The check is
dynamic, made at access time. Lookup and dynamic dispatch are unchanged.

**Marking.** A new global cell `<privates>` holds the store locations of
private members. A private declaration runs like a public one, and then
records the location just bound to the name:

```k
  rule private var X:Id; => var X; ~> markPrivate(X)
  rule private method F:Id(Xs:Ids) S => method F(Xs) S ~> markPrivate(F)
  rule <k> markPrivate(X) => .K ...</k>
       <env>... X |-> L ...</env>
       <privates> P => P SetItem(L) </privates>
```

Each object has its own locations, so privacy is recorded per object layer.

**Checking.** `lookupMember` searches the layers of an object. When it finds
the member in the layer of class `C`, it now returns `access(C, L)` instead
of `lookup(L)`. `access(C, L)` becomes `lookup(L)` only if `L` is not
private or `C` is the current class (`<crntClass>`, the class of the
running method). There is one rule for each place where `lookupMember` is
used: a plain expression, the function of a call, and an lvalue. In every
other case the execution gets stuck.

```k
  rule canAccess(C, L, CC, P) => notBool(L in P) orBool C ==K CC
  rule <k> access(C, L) => lookup(L) ...</k>
       <crntClass> CC </crntClass> <privates> P </privates>
    requires canAccess(C, L, CC, P)
  // + the same for (access(C, L))(Es) and lvalue(access(C, L))
```

Because the search stops at the first layer that has the name, a private
member hides the superclass members with the same name:

* **`ex04`:** `(new A()).x` gets stuck. It does not fall back to `B`'s
  public `x`.
* **`ex13`, `ex19`:** calls are still dynamically dispatched. In `ex19`,
  `B.f()` calls `get()`, which reaches `A`'s private `get`, and that call
  gets stuck.
* **Constructors:** `new` calls the constructor after the current class has
  been set to the object's class, so a private constructor still works with
  `new` (`ex02`).

## Exercise 2: dynamically typed KOOL

Fields work exactly as in Exercise 1. In typed KOOL, an object value
`objectClosure(C, ...)` carries the declared class `C` of the expression,
because `unsafeCast` is applied on assignment, parameter passing and
return. Member lookup therefore already starts at the static class. For
example, in `ex18`, `a.x` with `A a` (bound to a `B`) finds `A`'s private
`x`.

What changes is method calls, which now follow Java: **a private method of
the current class is not overridden**. For a call `o.X(...)`, the semantics
first looks `X` up statically, starting with the layer of `o`'s class. If it
finds `X` in the layer of the current class `CC`, and `X` is private there,
the call is bound to it. Otherwise `X` is dynamically dispatched from the
instance class, as before, and the access check of Exercise 1 applies.

```k
  rule <k> (objectClosure(C, EStack) . X
            => lookupMethod(C, EStack, X, CC, P))(_:Exps) ...</k>
       <crntClass> CC </crntClass> <privates> P </privates>

  rule lookupMethod(C, EStack, X, CC, P)
    => bindMethod(findMember(layersFrom(C, EStack), X), EStack, X, CC, P)
  rule bindMethod(access(CC, L), _, _, CC, P) => access(CC, L)  requires L in P
  rule bindMethod(_, EStack, X, _, _) => lookupMember(EStack, X)  [owise]
```

Implicit calls `get()` become `this.get()`, and `this` has the current class.
The tests that show the difference:

* **`ex13`:** `B.f()` calls `get()`. `B`'s `get` is private, so the call is
  bound to it and prints `5`. In untyped KOOL it printed `10`.
* **`ex19`:** both calls work. `f()` uses `B`'s private `get`, and `g()`
  uses `A`'s.
* **`ex16`:** in `B`, the private `get` that is found belongs to `C`, not to
  the current class. The call is dispatched dynamically to `A`'s public
  `get` and prints `10`.
* **`ex22`:** `B`'s `get` is public, so dynamic dispatch reaches `A`'s
  private `get`. The access check fails and execution gets stuck.

## Exercise 3: statically typed KOOL

The type checker rejects the two situations that would cause runtime errors
in Exercise 2. In both cases it prints the message expected by the tests
and gets stuck.

**Collecting private names.** Each `<classData>` gets a `<privates>` cell
holding the names of the class's private members. It is filled while the
class is being processed. `<ctenv>` is only added after the class is fully
processed, and any member lookup in the class waits for `<ctenv>`. So
`<privates>` is complete before it is ever read.

**1. Accessing a private member from another class.** This covers private
members of superclasses (`ex08`, `ex16`, `ex21`), and access from `Main` or
any other class. The lookup of `` `class`(C) . X `` checks the class where
`X` is found against `<inClass>`:

```k
  rule <k> `class`(C:Id) . X:Id => T ...</k>
       <inClass> CC </inClass>
       <className> C </className>
       <ctenv>... X |-> T:Type ...</ctenv>
       <privates> P </privates>
    requires notBool(X in P) orBool C ==K CC
  // otherwise: "Private member "X" of class "C" cannot be accessed in class "CC""
```

This is conservative, as the exercise says. `ex16` runs fine in dynamically
typed KOOL, because the call is dispatched to `A`'s public `get`. Here it is
rejected, because statically `get` is `C`'s private method.

**2. Overriding a public method with a private one.** For a private method
`F` in class `C`, `checkPrivate(F, C, C')` walks up from the superclass `C'`
to the closest class that declares `F`. If `F` is public there, it reports
`Method "F" cannot be private in class "C" because it is public in class
"C'"` (`ex22`). If `F` is private there, or no superclass declares it, the
method is accepted (`ex19`).

**Other changes.**

* **Overriding a private method:** `checkMethod`, the subtype check for
  overriding, now skips a superclass method that is private. A private
  method is not overridden, so the new method may have any type (`ex12`,
  `ex13`).
* **Private constructors with `new`:** `new C(...)` looks up the constructor
  through `ctorRef(C)`, which skips the privacy check. The dynamic semantics
  runs the constructor inside class `C`, so `new` with a private constructor
  is safe. A direct call such as `a.A()` from `Main` is still rejected
  (`ex02`).

---

## Test results

These were run with K v7.1.337. `make` passes in all three directories: all
provided tests give the expected output.

The tests the original Makefiles skip are also skipped here:

* `threads` in ex1/ex2;
* `cycle` in ex2;
* `return-object` in ex3.

`cycle` in ex3 is run with `--search`, as in the original Makefile.
