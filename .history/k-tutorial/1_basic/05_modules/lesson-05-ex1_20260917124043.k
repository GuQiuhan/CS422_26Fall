// Exercise 1: split Lesson 1.4, Exercise 2 (explicit priority/associativity
// version) across three modules: integers/brackets, addition/subtraction/
// negation, and multiplication/division. Priority declarations live in the
// main module, which imports all three.
module LESSON-05-EX1-ATOM
  syntax Int ::= r"[0-9]+" [token]
  syntax Exp ::= Int [group(atom)]
               | "(" Exp ")" [group(atom), bracket]
endmodule

module LESSON-05-EX1-ADD
  imports LESSON-05-EX1-ATOM

  syntax Exp ::= "-" Exp [group(neg)]
               | Exp "+" Exp [group(add)]
               | Exp "-" Exp [group(add)]
endmodule

module LESSON-05-EX1-MUL
  imports LESSON-05-EX1-ATOM

  syntax Exp ::= Exp "*" Exp [group(mul)]
               | Exp "/" Exp [group(mul)]
endmodule

module LESSON-05-EX1
  imports LESSON-05-EX1-ADD
  imports LESSON-05-EX1-MUL

  syntax priority atom > neg > mul > add
  syntax left mul
  syntax left add
endmodule
