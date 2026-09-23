
module TEST
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Val ::= Int | Bool

  syntax Exp ::=  "-" Exp [group(neg), seqstrict]
               > left:
                 Exp "*" Exp [group(mul), seqstrict]

  syntax priority neg > mul 
  
endmodule

