// Exercise 1: color if/else one color, (){} another color, on top of
// LESSON-09-C's formatting.
//
// Note: `true` and `false` are not terminals of any production declared
// in this module -- they come from the imported `BOOL-SYNTAX` module's
// own `Bool` productions, wherever a `Bool` non-terminal is embedded in
// a Stmt. We cannot retroactively attach a `color` attribute to a
// production declared in another module, so coloring `true`/`false`
// would require locally redeclaring the `Bool` literals (which would
// conflict/duplicate with `BOOL-SYNTAX`'s own declarations). We
// therefore color exactly what we can control here: the `if`/`else`
// keywords (one color) and the `(`, `)`, `{`, `}` punctuation (another
// color).
module LESSON-09-EX1
  imports BOOL

  syntax Stmt ::= "{" Stmt "}" [format(%1%i%n%2%d%n%3), colors(cyan, cyan)]
                | "{" "}" [format(%1%2), colors(cyan, cyan)]
                > right:
                  Stmt Stmt [format(%1%n%2)]
                | "if" "(" Bool ")" Stmt [format(%1 %2%3%4 %5), colors(magenta, cyan, cyan)]
                | "if" "(" Bool ")" Stmt "else" Stmt
                    [avoid, format(%1 %2%3%4 %5 %6 %7), colors(magenta, cyan, cyan, magenta)]
endmodule
