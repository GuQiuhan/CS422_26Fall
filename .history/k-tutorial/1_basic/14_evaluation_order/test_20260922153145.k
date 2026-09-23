
module TEST
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Val ::= Int | Bool

  syntax Exp ::= Val [group(atom)]
               | "-" Exp [group(neg), seqstrict]
               > left:
                 Exp "*" Exp [group(mul), seqstrict]

  syntax priority atom > neg > mul > add
  
endmodule

