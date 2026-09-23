module TEST
  syntax Exp ::= "-" Exp [group(neg)]
               > left:
                 Exp "*" Exp [group(mul)]
               | Exp "+" Exp [group(add)]

  syntax priority neg > mul
  syntax priority mul > add
endmodule


