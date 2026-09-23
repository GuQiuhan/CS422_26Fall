// Exercise 3: the file lesson-05-ex2-syntax.k has been moved to
// ex3-include/ and removed from this directory. Plain `kompile
// lesson-05-ex3.k` fails because the current working directory (the
// default include directory) no longer contains that file. Fix with:
//
//   kompile lesson-05-ex3.k -I ex3-include
requires "lesson-05-ex2-syntax.k"

module LESSON-05-EX3
  imports LESSON-05-EX2-SYNTAX

  rule colorOf(Banana()) => Yellow()
  rule colorOf(Blueberry()) => Blue()
  rule colorOf(Kiwi()) => Green()
  rule colorOf(Blackberry()) => Black()
endmodule
