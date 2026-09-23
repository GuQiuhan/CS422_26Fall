// Exercise (Optional cells): enable/increment/decrement/disable an
// optional counter cell.
module LESSON-17-EX-OPTIONAL
  imports INT

  syntax Stmt ::= "enable" | "increment" | "decrement" | "disable"
  syntax Stmts ::= List{Stmt,""}

  configuration <k> $PGM:Stmts </k>
                <counter multiplicity="?"> 0 </counter>

  rule <k> S:Stmt Ss:Stmts => S ~> Ss ...</k>
  rule <k> .Stmts => . ...</k>

  rule <k> enable => . ...</k>
       (.Bag => <counter> 0 </counter>)
  rule <k> disable => . ...</k>
       (<counter> _ </counter> => .Bag)

  rule <k> increment => . ...</k>
       <counter> N => N +Int 1 </counter>
  rule <k> decrement => . ...</k>
       <counter> N => N -Int 1 </counter>
endmodule
