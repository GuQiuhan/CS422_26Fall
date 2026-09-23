
module TEST
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Val ::= Int | Bool

  syntax Exp ::= Val [group(atom)]
               | "(" Exp ")" [group(atom), bracket]
               | "-" Exp [group(neg), seqstrict]
               > left:
                 Exp "*" Exp [group(mul), seqstrict]
               | Exp "/" Exp [group(mul), seqstrict]
               > left:
                 Exp "+" Exp [group(add), seqstrict]
               | Exp "-" Exp [group(add), seqstrict]

  syntax priority atom > neg > mul > add
  
endmodule

