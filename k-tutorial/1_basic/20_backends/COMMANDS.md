# Lesson 1.20 exercises

## Exercise 1

Reusing the minilang from Lesson 1.18, Exercise 2 (`../18_equality_and_conditionals/lesson-18-ex2-minilang-if.k`):

```
kompile ../18_equality_and_conditionals/lesson-18-ex2-minilang-if.k \
  --main-module LESSON-18-EX2-MINILANG-IF --syntax-module LESSON-18-EX2-MINILANG-IF-SYNTAX \
  --output-dir minilang-llvm-kompiled
krun ../18_equality_and_conditionals/minilang-if.pgm --definition minilang-llvm-kompiled

kompile ../18_equality_and_conditionals/lesson-18-ex2-minilang-if.k \
  --main-module LESSON-18-EX2-MINILANG-IF --syntax-module LESSON-18-EX2-MINILANG-IF-SYNTAX \
  --backend haskell --output-dir minilang-haskell-kompiled
krun ../18_equality_and_conditionals/minilang-if.pgm --definition minilang-haskell-kompiled
```
