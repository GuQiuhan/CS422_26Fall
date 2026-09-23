module TEST-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= "x" [group(atom)]
               > "-" Exp [group(neg)]
               > Exp "*" Exp [group(mul)]

  syntax priority atom > neg > mul
endmodule

