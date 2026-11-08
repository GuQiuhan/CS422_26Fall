// Copyright (c) Runtime Verification, Inc. All Rights Reserved.
// CS422 HW4 Exercise 1: code extracted from the tutorial's literate simple-untyped.md;
// all changes are marked "HW4 Exercise 1".

module SIMPLE-UNTYPED-SYNTAX
  imports DOMAINS-SYNTAX

  syntax Id ::= "main" [token]

  syntax Stmt ::= "var" Exps ";"
                | "function" Id "(" Ids ")" Block

  syntax Exp ::= Int | Bool | String | Id
               | "(" Exp ")"             [bracket]
               | "++" Exp
               > Exp "[" Exps "]"        [strict]
               > Exp "(" Exps ")"        [strict]
               | "-" Exp                 [strict]
               | "sizeOf" "(" Exp ")"    [strict]
               | "read" "(" ")"
               > left:
                 Exp "*" Exp             [strict, left]
               | Exp "/" Exp             [strict, left]
               | Exp "%" Exp             [strict, left]
               > left:
                 Exp "+" Exp             [strict, left]
               | Exp "-" Exp             [strict, left]
               > non-assoc:
                 Exp "<" Exp             [strict, non-assoc]
               | Exp "<=" Exp            [strict, non-assoc]
               | Exp ">" Exp             [strict, non-assoc]
               | Exp ">=" Exp            [strict, non-assoc]
               | Exp "==" Exp            [strict, non-assoc]
               | Exp "!=" Exp            [strict, non-assoc]
               > "!" Exp                 [strict]
               > left:
                 Exp "&&" Exp            [strict(1), left]
               | Exp "||" Exp            [strict(1), left]
               > "spawn" Block
               > Exp "=" Exp             [strict(2), right]

  syntax Ids  ::= List{Id,","}           [overload(Exps)]
  syntax Exps ::= List{Exp,","}          [overload(Exps), strict]  // automatically hybrid now
  syntax Exps ::= Ids
  syntax Val
  syntax Vals ::= List{Val,","}          [overload(Exps)]
  syntax Bottom
  syntax Bottoms ::= List{Bottom,","}    [overload(Exps)]
  syntax Ids ::= Bottoms

  syntax Block ::= "{" "}"
                | "{" Stmt "}"

  syntax Stmt ::= Block
                | Exp ";"                               [strict]
                | "if" "(" Exp ")" Block "else" Block   [avoid, strict(1)]
                | "if" "(" Exp ")" Block                [macro]
                | "while" "(" Exp ")" Block
                | "for" "(" Stmt Exp ";" Exp ")" Block
                | "return" Exp ";"                      [strict]
                | "return" ";"                          [macro]
                | "print" "(" Exps ")" ";"              [strict]
// NOTE: print strict allows non-deterministic evaluation of its arguments
// Either keep like this but document, or otherwise make Exps seqstrict.
// Of define and use a different expression list here, which is seqstrict.
                | "try" Block "catch" "(" Id ")" Block
                | "throw" Exp ";"                       [strict]
                | "join" Exp ";"                        [strict]
                | "acquire" Exp ";"                     [strict]
                | "release" Exp ";"                     [strict]
                | "rendezvous" Exp ";"                  [strict]
// HW4 Exercise 1: unlabeled break and continue (innermost loop only).
// They must be declared here, in the SYNTAX module, so that the program
// parser knows them.
                | "break" ";"
                | "continue" ";"

  syntax Stmt ::= Stmt Stmt                          [right]

// I wish I were able to write the following instead, but confuses the parser.
//
// syntax Stmts ::= List{Stmt,""}
// syntax Top ::= Stmt | "function" Id "(" Ids ")" Block
// syntax Pgm ::= List{Top,""}
//
// With that, I could have also eliminated the empty block

  rule if (E) S => if (E) S else {}
// HW4 Exercise 1: for is no longer desugared into while here (see the
// loop semantics below): with "continue", the desugared body {S Step;}
// would skip Step.
  rule var E1:Exp, E2:Exp, Es:Exps; => var E1; var E2, Es;
  rule var X:Id = E; => var X; X = E;

endmodule


module SIMPLE-UNTYPED
  imports SIMPLE-UNTYPED-SYNTAX
  imports DOMAINS

  syntax Val ::= Int | Bool | String
               | array(Int,Int)
               | lambda(Ids,Stmt)
  syntax Exp ::= Val
  syntax Exps ::= Vals
  syntax Vals ::= Bottoms
  syntax KResult ::= Val
                   | Vals  // TODO: should not need this

  // the syntax declarations below are required because the sorts are
  // referenced directly by a production and, because of the way KIL to KORE
  // is implemented, the configuration syntax is not available yet
  // should simply work once KIL is removed completely
  // check other definitions for this hack as well

  syntax ControlCell
  syntax ControlCellFragment

  configuration <T color="red">
                  <threads color="orange">
                    <thread multiplicity="*" type="Map" color="yellow">
                      <id color="pink"> -1 </id>
                      <k color="green"> $PGM:Stmt ~> execute </k>
                    //<br/> // TODO(KORE): support latex annotations #1799
                      <control color="cyan">
                        <fstack color="blue"> .List </fstack>
                        <xstack color="purple"> .List </xstack>
                        <lstack color="olive"> .List </lstack>
                      </control>
                    //<br/> // TODO(KORE): support latex annotations #1799
                      <env color="violet"> .Map </env>
                      <holds color="black"> .Map </holds>
                    </thread>
                  </threads>
                //<br/> // TODO(KORE): support latex annotations #1799
                  <genv color="pink"> .Map </genv>
                  <store color="white"> .Map </store>
                  <busy color="cyan"> .Set </busy>
                  <terminated color="red"> .Set </terminated>
                //<br/> // TODO(KORE): support latex annotations #1799
                  <input color="magenta" stream="stdin"> .List </input>
                  <output color="brown" stream="stdout"> .List </output>
                  <nextLoc color="gray"> 0 </nextLoc>
                </T>

  syntax KItem ::= "undefined"

  rule <k> var X:Id; => .K ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> undefined ...</store>
       <nextLoc> L => L +Int 1 </nextLoc>

  context var _:Id[HOLE];

  rule <k> var X:Id[N:Int]; => .K ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> array(L +Int 1, N)
                          (L +Int 1) ... (L +Int N) |-> undefined ...</store>
       <nextLoc> L => L +Int 1 +Int N </nextLoc>
    requires N >=Int 0

  syntax Id ::= "$1" [token] | "$2" [token]
  rule var X:Id[N1:Int, N2:Int, Vs:Vals];
    => var X[N1];
       {
         for(var $1 = 0; $1 <= N1 - 1; ++$1) {
           var $2[N2, Vs];
           X[$1] = $2;
         }
       }

  rule <k> function F(Xs) S => .K ...</k>
       <env> Env => Env[F <- L] </env>
       <store>... .Map => L |-> lambda(Xs, S) ...</store>
       <nextLoc> L => L +Int 1 </nextLoc>

  syntax KItem ::= "execute"
  rule <k> execute => main(.Exps); </k>
       <env> Env </env>
       <genv> .Map => Env </genv>

  rule <k> X:Id => V ...</k>
       <env>... X |-> L ...</env>
       <store>... L |-> V:Val ...</store>

  context ++(HOLE => lvalue(HOLE))
  rule <k> ++loc(L) => I +Int 1 ...</k>
       <store>... L |-> (I => I +Int 1) ...</store>

  rule I1 + I2 => I1 +Int I2
  rule Str1 + Str2 => Str1 +String Str2
  rule I1 - I2 => I1 -Int I2
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2 requires I2 =/=K 0
  rule I1 % I2 => I1 %Int I2 requires I2 =/=K 0
  rule - I => 0 -Int I
  rule I1 < I2 => I1 <Int I2
  rule I1 <= I2 => I1 <=Int I2
  rule I1 > I2 => I1 >Int I2
  rule I1 >= I2 => I1 >=Int I2

  rule V1:Val == V2:Val => V1 ==K V2
  rule V1:Val != V2:Val => V1 =/=K V2

  rule ! T => notBool(T)
  rule true  && E => E
  rule false && _ => false
  rule true  || _ => true
  rule false || E => E

// The [anywhere] feature is underused, because it would only be used
// at the top of the computation or inside the lvalue wrapper. So it
// may not be worth, or we may need to come up with a special notation
// allowing us to enumerate contexts for [anywhere] rules.
  rule V:Val[N1:Int, N2:Int, Vs:Vals] => V[N1][N2, Vs]
    [anywhere]

  rule array(L,_)[N:Int] => lookup(L +Int N)
    [anywhere]

  rule sizeOf(array(_,N)) => N

  syntax KItem ::=  (Map,K,ControlCellFragment)

  rule <k> lambda(Xs,S)(Vs:Vals) ~> K => mkDecls(Xs,Vs) S return; </k>
       <control>
         <fstack> .List => ListItem((Env,K,C)) ...</fstack>
         C
       </control>
       <env> Env => GEnv </env>
       <genv> GEnv </genv>

  rule <k> return(V:Val); ~> _ => V ~> K </k>
       <control>
         <fstack> ListItem((Env,K,C)) => .List ...</fstack>
         (_ => C)
       </control>
       <env> _ => Env </env>

  syntax Val ::= "nothing"
  rule return; => return nothing;

  rule <k> read() => I ...</k> <input> ListItem(I:Int) => .List ...</input>

  context (HOLE => lvalue(HOLE)) = _

  rule <k> loc(L) = V:Val => V ...</k> <store>... L |-> (_ => V) ...</store>

  rule {} => .K
  rule <k> { S } => S ~> setEnv(Env) ...</k>  <env> Env </env>

  rule S1:Stmt S2:Stmt => S1 ~> S2

  rule _:Val; => .K

  rule if ( true) S else _ => S
  rule if (false) _ else S => S

// HW4 Exercise 1: break and continue.
//
// Both while and for are turned into one internal loop construct,
//     loop(Cond, Step, Body)
// where Step is the statement run after each iteration ({} for while).
// Entering a loop pushes a loop frame on the new <lstack> cell, similar to
// the exception frames on <xstack>.  The frame records everything needed to
// leave the loop or to start its next iteration:
//     lframe(Cond, Step, Body, K, Env, C)
// where K is the computation after the loop, Env is the environment at
// loop entry and C is the rest of the control cell (function and exception
// stacks), so that break/continue also discard any try blocks entered
// inside the loop body.
//   * break;    pops the frame and continues with K (after the loop);
//   * continue; keeps the frame and runs Step, then the next iteration;
//   * when the loop ends normally, popl pops the frame.
// Variables declared in the body are local to it, because the body is a
// block and break/continue restore Env.

  syntax Stmt ::= loop(Exp, Stmt, Block)
                | iterate(Exp, Stmt, Block)
  syntax KItem ::= lframe(Exp, Stmt, Block, K, Map, ControlCellFragment)
                 | "popl"

  rule while (E) S => loop(E, {}, S)
  rule for(Start Cond; Step) S => {Start loop(Cond, Step;, S)}

  rule <k> (loop(E, St, S) => iterate(E, St, S) ~> popl) ~> K </k>
       <control>
         <lstack> .List => ListItem(lframe(E, St, S, K, Env, C)) ...</lstack>
         C
       </control>
       <env> Env </env>

  rule iterate(E, St, S) => if (E) {S St iterate(E, St, S)}

  rule <k> popl => .K ...</k>
       <lstack> ListItem(_) => .List ...</lstack>

  rule <k> break; ~> _ => K </k>
       <control>
         <lstack> ListItem(lframe(_, _, _, K, Env, C)) => .List ...</lstack>
         (_ => C)
       </control>
       <env> _ => Env </env>

  rule <k> continue; ~> _ => St ~> iterate(E, St, S) ~> popl ~> K </k>
       <control>
         <lstack> ListItem(lframe(E, St, S, K, Env, C)) ...</lstack>
         (_ => C)
       </control>
       <env> _ => Env </env>

  rule <k> print(V:Val, Es => Es); ...</k> <output>... .List => ListItem(V) </output>
  rule print(.Vals); => .K

  syntax KItem ::= (Id,Stmt,K,Map,ControlCellFragment)

  syntax KItem ::= "popx"

  rule <k> (try S1 catch(X) {S2} => S1 ~> popx) ~> K </k>
       <control>
         <xstack> .List => ListItem((X, S2, K, Env, C)) ...</xstack>
         C
       </control>
       <env> Env </env>

  rule <k> popx => .K ...</k>
       <xstack> ListItem(_) => .List ...</xstack>

  rule <k> throw V:Val; ~> _ => { var X = V; S2 } ~> K </k>
       <control>
         <xstack> ListItem((X, S2, K, Env, C)) => .List ...</xstack>
         (_ => C)
       </control>
       <env> _ => Env </env>

  rule <thread>...
         <k> spawn S => !T:Int ...</k>
         <env> Env </env>
       ...</thread>
       (.Bag => <thread>...
               <k> S </k>
               <env> Env </env>
               <id> !T </id>
             ...</thread>)

  rule (<thread>... <k>.K</k> <holds>H</holds> <id>T</id> ...</thread> => .Bag)
       <busy> Busy => Busy -Set keys(H) </busy>
       <terminated>... .Set => SetItem(T) ...</terminated>

  rule <k> join T:Int; => .K ...</k>
       <terminated>... SetItem(T) ...</terminated>

  rule <k> acquire V:Val; => .K ...</k>
       <holds>... .Map => V |-> 0 ...</holds>
       <busy> Busy (.Set => SetItem(V)) </busy>
    requires (notBool(V in Busy))

  rule <k> acquire V; => .K ...</k>
       <holds>... V:Val |-> (N => N +Int 1) ...</holds>

  rule <k> release V:Val; => .K ...</k>
       <holds>... V |-> (N => N -Int 1) ...</holds>
    requires N >Int 0

  rule <k> release V; => .K ...</k> <holds>... V:Val |-> 0 => .Map ...</holds>
       <busy>... SetItem(V) => .Set ...</busy>

  rule <k> rendezvous V:Val; => .K ...</k>
       <k> rendezvous V; => .K ...</k>

  syntax Stmt ::= mkDecls(Ids,Vals)  [function]
  rule mkDecls((X:Id, Xs:Ids), (V:Val, Vs:Vals)) => var X=V; mkDecls(Xs,Vs)
  rule mkDecls(.Ids,.Vals) => {}

  syntax Exp ::= lookup(Int)
  rule <k> lookup(L) => V ...</k> <store>... L |-> V:Val ...</store>

// TODO: eliminate the env wrapper, like we did in IMP++

  syntax KItem ::= setEnv(Map)
  rule <k> setEnv(Env) => .K ...</k> <env> _ => Env </env>

  rule (setEnv(_) => .K) ~> setEnv(_)

// For parsing reasons, we prefer to allow lvalue to take a K

  syntax Exp ::= lvalue(K)
  syntax Val ::= loc(Int)

// Local variable

  rule <k> lvalue(X:Id => loc(L)) ...</k> <env>... X |-> L:Int ...</env>

// Array element: evaluate the array and its index;
// then the array lookup rule above applies.

  context lvalue(_::Exp[HOLE::Exps])
  context lvalue(HOLE::Exp[_::Exps])

// Finally, return the address of the desired object member

  rule lvalue(lookup(L:Int) => loc(L))

  syntax Map ::= Int "..." Int "|->" K [function]
  rule N...M |-> _ => .Map  requires N >Int M
  rule N...M |-> K => N |-> K (N +Int 1)...M |-> K  requires N <=Int M

endmodule

