module TEST-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= Int [group(atom)]
               | Bool [group(atom)]
               | "(" Exp ")" [group(atom), bracket]
               | "-" Exp [group(neg)]
               > left:
                 Exp "*" Exp [group(mul)]
               | Exp "/" Exp [group(mul)]

  syntax priority atom > neg > mul

endmodule

