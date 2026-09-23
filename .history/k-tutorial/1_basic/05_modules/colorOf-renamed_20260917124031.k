// Exercise: rename COLOROF to COLOROF-MAIN. By default `kompile
// colorOf-renamed.k` looks for a main semantics module named
// COLOROF-RENAMED (derived from the file name) and a main syntax module
// named COLOROF-RENAMED-SYNTAX, neither of which exist any more, so
// compilation fails with an error about a missing main module. Fix it by
// running:
//
//   kompile colorOf-renamed.k --main-module COLOROF-MAIN --syntax-module COLOROF-SYNTAX
requires "fruits.k"
requires "colors.k"

module COLOROF-SYNTAX
  imports COLORS
  imports FRUITS

  syntax Color ::= colorOf(Fruit) [function]
endmodule

module COLOROF-MAIN
  imports COLOROF-SYNTAX

  rule colorOf(Banana()) => Yellow()
  rule colorOf(Blueberry()) => Blue()
endmodule
