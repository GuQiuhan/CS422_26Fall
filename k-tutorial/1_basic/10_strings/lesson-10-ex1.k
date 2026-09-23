module LESSON-10-EX1
  imports STRING
  imports BOOL
  imports INT

  syntax String ::= ltrim(String) [function]
  rule ltrim(S) => ltrim(substrString(S, 1, lengthString(S)))
    requires lengthString(S) >Int 0 andBool substrString(S, 0, 1) ==String " "
  rule ltrim(S) => S [owise]

  syntax String ::= firstWordOf(String) [function]
  rule firstWordOf(S) => substrString(S, 0, findString(S, " ", 0))
    requires findString(S, " ", 0) >=Int 0
  rule firstWordOf(S) => S [owise]

  syntax String ::= firstWords(String) [function]
  rule firstWords(P) => ""
    requires findString(P, ".", 0) <Int 0
  rule firstWords(P) =>
       firstWordOf(substrString(P, 0, findString(P, ".", 0)))
       +String "."
       +String firstWords(ltrim(substrString(P, findString(P, ".", 0) +Int 1, lengthString(P))))
    requires findString(P, ".", 0) >=Int 0
endmodule
