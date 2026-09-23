
module TEST

  syntax Exp ::=  "-" Exp [group(neg), seqstrict]
               > left:
                 Exp "*" Exp [group(mul), seqstrict]

  syntax priority neg > mul 
  
endmodule

