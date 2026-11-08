// Copyright (c) Runtime Verification, Inc. All Rights Reserved.
// CS422 HW4 Exercise 2: code extracted from the tutorial's literate simple-typed-dynamic.md;
// all changes are marked "HW4 Exercise 2".

module SIMPLE-TYPED-DYNAMIC-SYNTAX
  imports DOMAINS-SYNTAX

  syntax Id ::= "main" [token]

  syntax Type ::= "void" | "int" | "bool" | "string"
                | Type "[" "]"
                | "(" Type ")"           [bracket]
                > Types "->" Type
  syntax Types ::= List{Type,","}        [overload(exps)]

  syntax Param ::= Type Id
  syntax Params ::= List{Param,","}

  syntax Stmt ::= Type Exps ";"
                | Type Id "(" Params ")" Block

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

  syntax Exps ::= List{Exp,","}          [strict, overload(exps)]
  syntax Val
  syntax Vals ::= List{Val,","}          [overload(exps)]

  syntax Block ::= "{" "}"
                | "{" Stmt "}"

  syntax Stmt ::= Block
                | Exp ";"                               [strict]
                | "if" "(" Exp ")" Block "else" Block   [avoid, strict(1)]
                | "if" "(" Exp ")" Block                [macro]
                | "while" "(" Exp ")" Block
                | "for" "(" Stmt Exp ";" Exp ")" Block  [macro]
                | "print" "(" Exps ")" ";"              [strict]
                | "return" Exp ";"                      [strict]
                | "return" ";"
                | "try" Block "catch" "(" Param ")" Block
            | "throw" Exp ";"                       [strict]
                | "join" Exp ";"                        [strict]
                | "acquire" Exp ";"                     [strict]
                | "release" Exp ";"                     [strict]
                | "rendezvous" Exp ";"                  [strict]

  syntax Stmt ::= Stmt Stmt                          [right]

  rule if (E) S => if (E) S else {}
  rule for(Start Cond; Step) {S:Stmt} => {Start while(Cond){S Step;}}
  rule for(Start Cond; Step) {} => {Start while(Cond){Step;}}
  rule T:Type E1:Exp, E2:Exp, Es:Exps; => T E1; T E2, Es;               [anywhere]
  rule T:Type X:Id = E; => T X; X = E;                                  [anywhere]

endmodule


module SIMPLE-TYPED-DYNAMIC
  imports SIMPLE-TYPED-DYNAMIC-SYNTAX
  imports DOMAINS

  syntax Val ::= Int | Bool | String
               | array(Type,Int,Int)
               | lambda(Type,Params,Stmt)
  syntax Exp ::= Val
  syntax Exps ::= Vals
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
                    <thread multiplicity="*" color="yellow" type="Map">
                      <id color="pink"> 0 </id>
                      <k color="green"> ($PGM:Stmt ~> execute) </k>
//                      <br/>
                      <control color="cyan">
                        <fstack color="blue"> .List </fstack>
                        <xstack color="purple"> .List </xstack>
                        <returnType color="LimeGreen"> void </returnType>
                       </control>
//                      <br/>
                      <env color="violet"> .Map </env>
                      <holds color="black"> .Map </holds>
                    </thread>
                  </threads>
//                  <br/>
                  <genv color="pink"> .Map </genv>
                  <store color="white"> .Map </store>
                  <busy color="cyan">.Set</busy>
                  <terminated color="red"> .Set </terminated>
                  <input color="magenta" stream="stdin"> .List </input>
                  <output color="brown" stream="stdout"> .List </output>
                  <nextLoc color="gray"> 0 </nextLoc>
                </T>

  syntax KItem ::= undefined(Type)

  rule <k> T:Type X:Id; => .K ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> undefined(T) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>

  rule <k> T:Type X:Id[N:Int]; => .K ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> array(T, L +Int 1, N)
                          (L +Int 1)...(L +Int N) |-> undefined(T) ...</store>
       <nextLoc> L:Int => L +Int 1 +Int N </nextLoc>
    requires N >=Int 0

  context _:Type _::Exp[HOLE::Exps];

// TODO: Check the desugaring below to be consistent with the one for untyped simple

  syntax Id ::= "$1" [token] | "$2" [token]
  rule T:Type X:Id[N1:Int, N2:Int, Vs:Vals];
    => T[]<Vs> X[N1];
       {
         T[][]<Vs> $1=X;
         for(int $2=0; $2 <= N1 - 1; ++$2) {
           T X[N2,Vs];
           $1[$2] = X;
         }
       }

  rule <k> T:Type F:Id(Ps:Params) S => .K ...</k>
       <env> Env => Env[F <- L] </env>
       <store>... .Map => L |-> lambda(T, Ps, S) ...</store>
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
       <store>... L |-> (I:Int => I +Int 1) ...</store>

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

// Same comment as for simple untyped regarding [anywhere]
  rule V:Val[N1:Int, N2:Int, Vs:Vals] => V[N1][N2, Vs]
    [anywhere]

// Same comment as for simple untyped regarding [anywhere]
  rule array(_:Type, L:Int, M:Int)[N:Int] => lookup(L +Int N)
    requires N >=Int 0 andBool N <Int M  [anywhere]

  rule sizeOf(array(_,_,N)) => N

  syntax KItem ::= (Type,Map,K,ControlCellFragment)

  rule <k> lambda(T,Ps,S)(Vs:Vals) ~> K => mkDecls(Ps,Vs) S return; </k>
       <control>
         <fstack> .List => ListItem((T',Env,K,C)) ...</fstack>
         <returnType> T' => T </returnType>
         C
       </control>
       <env> Env => GEnv </env>
       <genv> GEnv </genv>

  rule <k> return V:Val; ~> _ => V ~> K </k>
       <control>
         <fstack> ListItem((T',Env,K,C)) => .List ...</fstack>
         <returnType> T => T' </returnType>
         (_ => C)
       </control>
       <env> _ => Env </env>
    requires typeOf(V) ==K T   // check the type of the returned value

  syntax Val ::= nothing(Type)
  rule <k> return; => return nothing(T); ...</k> <returnType> T </returnType>

  rule <k> read() => I ...</k> <input> ListItem(I:Int) => .List ...</input>

  context (HOLE => lvalue(HOLE)) = _

  rule <k> loc(L) = V:Val => V ...</k> <store>... L |-> (V' => V) ...</store>
    requires typeOf(V) ==K typeOf(V')

  rule {} => .K
  rule <k> { S } => S ~> setEnv(Env) ...</k>  <env> Env </env>

  rule S1:Stmt S2:Stmt => S1 ~> S2

  rule _:Val; => .K

  rule if ( true) S else _ => S
  rule if (false) _ else S => S

  rule while (E) S => if (E) {S while(E)S}

  rule <k> print(V:Val, Es => Es); ...</k> <output>... .List => ListItem(V) </output>
    requires typeOf(V) ==K int orBool typeOf(V) ==K string
  rule print(.Vals); => .K

  syntax KItem ::= (Param,Stmt,K,Map,ControlCellFragment)  // Param instead of Id

  syntax KItem ::= "popx"

  rule <k> (try S1 catch(P) S2 => S1 ~> popx) ~> K </k>
       <control>
         <xstack> .List => ListItem((P, S2, K, Env, C)) ...</xstack>
         C
       </control>
       <env> Env </env>

  rule <k> popx => .K ...</k>
       <xstack> ListItem(_) => .List ...</xstack>

// HW4 Exercise 2: typed exceptions.
// The innermost handler catches the thrown value only if the value's type
// is the type of the handler's parameter.  Otherwise that handler is popped
// and the same value is thrown again, i.e., it propagates to the next
// enclosing try-catch.  If no handler has the right type, the execution
// gets stuck with an uncaught throw on top of <k>.
  rule <k> throw V:Val; ~> _ => { T X = V; S2 } ~> K </k>
       <control>
         <xstack> ListItem((T:Type X:Id, S2, K, Env, C)) => .List ...</xstack>
         (_ => C)
       </control>
       <env> _ => Env </env>
    requires typeOf(V) ==K T

  rule <k> throw V:Val; ...</k>
       <xstack> ListItem((T:Type _:Id, _:Stmt, _:K, _:Map, _:ControlCellFragment)) => .List ...</xstack>
    requires typeOf(V) =/=K T

   rule <thread>...
          <k> spawn S => !T:Int +Int 1 ...</k>
          <env> Env </env>
        ...</thread>
        (.Bag => <thread>...
                <k> S </k>
                <env> Env </env>
                <id> !T +Int 1 </id>
              ...</thread>)

   rule (<thread>... <k>.K</k> <holds>H</holds> <id>T</id> ...</thread> => .Bag)
        <busy> Busy => Busy -Set keys(H) </busy>
        <terminated>... .Set => SetItem(T) ...</terminated>

   rule <k> join T:Int; => .K ...</k>
        <terminated>... SetItem(T) ...</terminated>

   rule <k> acquire V:Val; => .K ...</k>
        <holds>... .Map => V |-> 0 ...</holds>
        <busy> Busy (.Set => SetItem(V)) </busy>
     requires (notBool(V in Busy:Set))

   rule <k> acquire V; => .K ...</k>
        <holds>... V:Val |-> (N:Int => N +Int 1) ...</holds>

   rule <k> release V:Val; => .K ...</k>
        <holds>... V |-> (N => N:Int -Int 1) ...</holds>
      requires N >Int 0

   rule <k> release V; => .K ...</k> <holds>... V:Val |-> 0 => .Map ...</holds>
        <busy>... SetItem(V) => .Set ...</busy>

   rule <k> rendezvous V:Val; => .K ...</k>
        <k> rendezvous V; => .K ...</k>

  syntax Stmt ::= mkDecls(Params,Vals)  [function]
  rule mkDecls((T:Type X:Id, Ps:Params), (V:Val, Vs:Vals))
    => T X=V; mkDecls(Ps,Vs)
  rule mkDecls(.Params,.Vals) => {}

  syntax Exp ::= lookup(Int)  // see NOTES.md for why Exp instead of KItem
  rule <k> lookup(L) => V ...</k> <store>... L |-> V:Val ...</store>

// TODO: same comment regarding setEnv(...) as for simple untyped

  syntax KItem ::= setEnv(Map)
  rule <k> setEnv(Env) => .K ...</k>  <env> _ => Env </env>
  rule (setEnv(_) => .K) ~> setEnv(_)

  syntax Exp ::= lvalue(K)
  syntax Val ::= loc(Int)

  rule <k> lvalue(X:Id => loc(L)) ...</k>  <env>... X |-> L:Int ...</env>

  //context lvalue(_[HOLE])
  //context lvalue(HOLE[_])
  context lvalue(_::Exp[HOLE::Exps])
  context lvalue(HOLE::Exp[_::Exps])

  rule lvalue(lookup(L:Int) => loc(L))

  syntax Type ::= Type "<" Vals ">"  [function]
  rule T:Type<_,Vs:Vals> => T[]<Vs>
  rule T:Type<.Vals> => T

  syntax Map ::= Int "..." Int "|->" K [function]
  rule N...M |-> _ => .Map  requires N >Int M
  rule N...M |-> K => N |-> K (N +Int 1)...M |-> K  requires N <=Int M

// Type of a value.
  syntax Type ::= typeOf(K)  [function]
  rule typeOf(_:Int) => int
  rule typeOf(_:Bool) => bool
  rule typeOf(_:String) => string
  rule typeOf(array(T,_,_)) => (T[])   // () needed! K parses [] as "no tags"
  rule typeOf(lambda(T,Ps,_)) => getTypes(Ps) -> T
  rule typeOf(undefined(T)) => T
  rule typeOf(nothing(T)) => T

  syntax Types ::= getTypes(Params)  [function]
  rule getTypes(T:Type _:Id) => T, .Types   // I would like to not use .Types
  rule getTypes(T:Type _:Id, P, Ps) => T, getTypes(P,Ps)
  rule getTypes(.Params) => void, .Types
endmodule

