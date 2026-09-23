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
               > left:
                 Exp "+" Exp [group(add)]
               | Exp "-" Exp [group(add)]

  syntax Exp ::= "!" Exp [group(not)]
               > non-assoc:
                 Exp "<" Exp [group(cmp)]
               | Exp "<=" Exp [group(cmp)]
               | Exp ">" Exp [group(cmp)]
               | Exp ">=" Exp [group(cmp)]
               | Exp "==" Exp [group(cmp)]
               | Exp "!=" Exp [group(cmp)]
               > left:
                 Exp "&&" Exp [group(booland)]
               | Exp "^" Exp [group(boolxor)]
               | Exp "||" Exp [group(boolor)]

  syntax priority atom > neg > mul > add > not > cmp > booland > boolxor > boolor
endmodule

