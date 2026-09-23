
module TEST

  syntax Exp ::=  "-" Exp [group(neg)]
               > left:
                 Exp "*" Exp [group(mul)]

  syntax priority neg > mul 
  
endmodule

