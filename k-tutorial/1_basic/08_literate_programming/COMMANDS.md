# Commands for Lesson 1.8 exercises

Body exercises:

```
kompile README.md --main-module LESSON-08
krun plus.int
```

```
kompile README.md --main-module LESSON-08
krun foo.int
```

## Exercises

1. Compile with the `foo` block excluded, then confirm `foo` is a parse error:

```
kompile README.md --main-module LESSON-08 --md-selector 'k & (! foo)'
krun foo.int
```

This fails to parse because with the `foo` block excluded, the `foo(Int)`
production is never declared, so `foo(0)` is not valid syntax in the
resulting definition.

2. Compiling Lesson 1.3's README.md directly fails because it contains
multiple K code blocks belonging to different, mutually-inconsistent
grammars for `Boolean` (the tutorial redefines the grammar several times
as the lesson progresses, sometimes marking bad/ambiguous examples with
the `.error` selector so they are excluded by default already, but the
various correct iterations of the grammar -- `LESSON-03-A` through
`LESSON-03-E` -- still all land in the file's default `k` selector
together and conflict / duplicate). Select just the last, complete
iteration's module, e.g.:

```
kompile 03-parsing.md --main-module LESSON-03-E --md-selector 'k & (! error)'
```

(Adjust the selector expression to match whichever code blocks actually
need excluding once you inspect the specific markdown source.)

3. See calculator.md, compiled with:

```
kompile calculator.md --main-module CALCULATOR --syntax-module CALCULATOR-SYNTAX
krun calc.exp
```
