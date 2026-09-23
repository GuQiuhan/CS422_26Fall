// Exercise (Parsing Syntactic Lists in Programs): concat
module LESSON-12-EX-CONCAT
  imports STRING

  syntax Strings ::= List{String,","}

  syntax String ::= concat(Strings) [function]
  rule concat(.Strings) => ""
  rule concat(S:String, Ss:Strings) => S +String concat(Ss)
endmodule
