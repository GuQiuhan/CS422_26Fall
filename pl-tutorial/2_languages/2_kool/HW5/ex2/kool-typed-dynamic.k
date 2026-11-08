// Copyright (c) Runtime Verification, Inc. All Rights Reserved.
// CS422 HW5 Exercise 2: code extracted from the tutorial's literate kool-typed-dynamic.md;
// all changes are marked "HW5 Exercise 2".

module KOOL-TYPED-DYNAMIC-SYNTAX
  imports DOMAINS-SYNTAX

  syntax Id ::= "Object" [token] | "Main" [token]

  syntax Type ::= "void" | "int" | "bool" | "string"
                | Id                              // KOOL class
                | Type "[" "]"
                | "(" Type ")"           [bracket]
                > Types "->" Type
  // TODO(KORE): drop klabel once issues #1913 are fixed
  syntax Types ::= List{Type,","}   [symbol(_,_::Types)]
  /*
  syntax Types ::= List{Type,","}
  */

  syntax Param ::= Type Id
  syntax Params ::= List{Param,","}

  syntax Stmt ::= Type Exps ";" [avoid]
                | Type Id "(" Params ")" Block    // stays like in typed SIMPLE
                // HW5 Exercise 2: optional "private" before member declarations
                | "private" Type Exps ";"
                | "private" Type Id "(" Params ")" Block
                | "class" Id Block                // KOOL
                | "class" Id "extends" Id Block   // KOOL

  syntax Exp ::= Int | Bool | String | Id
               | "this"                                 // KOOL
               | "super"                                // KOOL
               | "(" Exp ")"             [bracket]
               | "++" Exp
               | Exp "instanceOf" Id     [strict(1)]    // KOOL
               | "(" Id ")" Exp          [strict(2)]    // KOOL  cast
               | "new" Id "(" Exps ")"   [strict(2)]    // KOOL
               | Exp "." Id                             // KOOL
               > Exp "[" Exps "]"        [strict]
               > Exp "(" Exps ")"        [strict(2)]    // was strict in SIMPLE
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
  rule for(Start Cond; Step) {S::Stmt} => {Start while(Cond){S Step;}}
  rule T::Type E1::Exp, E2::Exp, Es::Exps; => T E1; T E2, Es;           [anywhere]
  rule T::Type X::Id = E; => T X; X = E;                                [anywhere]
  // HW5 Exercise 2: the same desugaring for private fields
  rule private T::Type E1::Exp, E2::Exp, Es::Exps; => private T E1; private T E2, Es;  [anywhere]
  rule private T::Type X::Id = E; => private T X; X = E;                                [anywhere]

  rule class C:Id S => class C extends Object S                     // KOOL

endmodule

module KOOL-TYPED-DYNAMIC
  imports KOOL-TYPED-DYNAMIC-SYNTAX
  imports DOMAINS

  // the syntax declarations below are required because the sorts are
  // referenced directly by a production and, because of the way KIL to KORE
  // is implemented, the configuration syntax is not available yet
  // should simply work once KIL is removed completely
  // check other definitions for this hack as well
  syntax EnvCell
  syntax ControlCellFragment
  syntax EnvStackCell
  syntax CrntObjCellFragment

  configuration <T color="red">
                  <threads color="orange">
                    <thread multiplicity="*" type="Set" color="yellow">
                      <k color="green"> ($PGM:Stmt ~> execute) </k>
                    //<br/> // TODO(KORE): support latex annotations #1799
                      <control color="cyan">
                        <fstack color="blue"> .List </fstack>
                        <xstack color="purple"> .List </xstack>
                        <returnType color="LimeGreen"> void </returnType>  // KOOL
                      //<br/> // TODO(KORE): support latex annotations #1799
                        <crntObj color="Fuchsia">  // KOOL
                           <crntClass> Object </crntClass>
                           <envStack> .List </envStack>
                           <location multiplicity="?"> .K </location>
                        </crntObj>
                      </control>
                    //<br/> // TODO(KORE): support latex annotations #1799
                      <env color="violet"> .Map </env>
                      <holds color="black"> .Map </holds>
                      <id color="pink"> 0 </id>
                    </thread>
                  </threads>
                //<br/> // TODO(KORE): support latex annotations #1799
                  <store color="white"> .Map </store>
                  <busy color="cyan">.Set </busy>
                  <terminated color="red"> .Set </terminated>
                  <input color="magenta" stream="stdin"> .List </input>
                  <output color="brown" stream="stdout"> .List </output>
                  <nextLoc color="gray"> 0 </nextLoc>
                  <privates> .Set </privates>  // HW5 Exercise 2: locations of private members
                //<br/> // TODO(KORE): support latex annotations #1799
                  <classes color="Fuchsia">        // KOOL
                     <classData multiplicity="*" type="Map" color="Fuchsia">
                        <className color="Fuchsia"> Main </className>
                        <baseClass color="Fuchsia"> Object </baseClass>
                        <declarations color="Fuchsia"> .K </declarations>
                     </classData>
                  </classes>
                </T>

  syntax Val ::= Int | Bool | String
               | array(Type,Int,Int)
  syntax Exp ::= Val
  syntax Exps ::= Vals
  syntax KResult ::= Val
  syntax KResult ::= Vals


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


  rule V:Val[N1:Int, N2:Int, Vs:Vals] => V[N1][N2, Vs]
    [anywhere]

  rule array(_:Type, L:Int, M:Int)[N:Int] => lookup(L +Int N)
    requires N >=Int 0 andBool N <Int M  [anywhere]

  rule sizeOf(array(_,_,N)) => N


  syntax Val ::= nothing(Type)
  rule <k> return; => return nothing(T); ...</k> <returnType> T </returnType>


  rule <k> read() => I ...</k> <input> ListItem(I:Int) => .List ...</input>


  context (HOLE => lvalue(HOLE)) = _


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

  syntax Exp ::= lookup(Int)
  rule <k> lookup(L) => V ...</k> <store>... L |-> V:Val ...</store>

  syntax KItem ::= setEnv(Map)
  rule <k> setEnv(Env) => .K ...</k>  <env> _ => Env </env>
  rule (setEnv(_) => .K) ~> setEnv(_)

  syntax Exp ::= lvalue(K)
  syntax Val ::= loc(Int)
  rule <k> lvalue(X:Id => loc(L)) ...</k>  <env>... X |-> L:Int ...</env>

  context lvalue(_::Exp[HOLE::Exps])
  context lvalue(HOLE::Exp[_::Exps])

  rule lvalue(lookup(L:Int) => loc(L))

  syntax Type ::= Type "<" Vals ">"  [function]
  rule T:Type<_,Vs:Vals> => T[]<Vs>
  rule T:Type<.Vals> => T

  syntax Map ::= Int "..." Int "|->" K [function]
  rule N...M |-> _ => .Map  requires N >Int M
  rule N...M |-> K => N |-> K (N +Int 1)...M |-> K  requires N <=Int M

  syntax Type ::= typeOf(K)  [function]
  rule typeOf(_:Int) => int
  rule typeOf(_:Bool) => bool
  rule typeOf(_:String) => string
  rule typeOf(array(T,_,_)) => (T[])
  rule typeOf(undefined(T)) => T
  rule typeOf(nothing(T)) => T

  syntax Types ::= getTypes(Params)  [function]
  rule getTypes(T:Type _:Id) => T, .Types
  rule getTypes(T:Type _:Id, P, Ps) => T, getTypes(P,Ps)
  rule getTypes(.Params) => void, .Types

  syntax KItem ::= "execute"
  rule <k> execute => new Main(.Exps); </k> <env> .Map </env>

 syntax Val ::= objectClosure(Id,List)
              | methodClosure(Type,Id,Int,Params,Stmt)

  syntax KItem ::= fstackFrame(Map, K, List, Type, K)

  rule <k> methodClosure(_->T,Class,OL,Ps,S)(Vs:Vals) ~> K
           => mkDecls(Ps,Vs) S return; </k>
       <env> Env => .Map </env>
       <store>... OL |-> objectClosure(_, EStack)...</store>
     //<br/> // TODO(KORE): support latex annotations #1799
       <control>
          <fstack> .List => ListItem(fstackFrame(Env, K, XS, T', <crntObj> Obj' </crntObj>)) ...</fstack>
          <xstack> XS </xstack>
          <returnType> T' => T </returnType>
          <crntObj> Obj' => <crntClass> Class </crntClass> <envStack> EStack </envStack> </crntObj>
       </control>

  rule <k> return V:Val; ~> _
           => subtype(typeOf(V), T) ~> true? ~> unsafeCast(V, T) ~> K
       </k>
       <control>
         <fstack> ListItem(fstackFrame(Env, K, XS, RT, <crntObj> CO </crntObj>)) => .List ...</fstack>
         <xstack> _ => XS </xstack>
         <returnType> T:Type => RT </returnType>
         <crntObj> _ => CO </crntObj>
       </control>
       <env> _ => Env </env>

  rule <k> loc(L) = V:Val
           => subtype(typeOf(V),typeOf(V')) ~> true?
              ~> unsafeCast(V, typeOf(V')) ...</k>
       <store>... L |-> (V' => unsafeCast(V, typeOf(V'))) ...</store>

  syntax KItem ::= xstackFrame(Param, Stmt, K, Map, K)
  syntax KItem ::= "popx"

  rule <k> (try S1 catch(P) S2 => S1 ~> popx) ~> K </k>
       <control>
         <xstack> .List => ListItem(xstackFrame(P, S2, K, Env, C)) ...</xstack>
         C
       </control>
       <env> Env </env>

  rule <k> popx => .K ...</k>
       <xstack> ListItem(_) => .List ...</xstack>

  rule <k> throw V:Val; ~> _
        => if (subtype(typeOf(V),T)) { T X = V; S2 } else { throw V; } ~> K
       </k>
       <control>
         <xstack> ListItem(xstackFrame(T:Type X:Id, S2, K, Env, C)) => .List ...</xstack>
         (_ => C)
       </control>
       <env> _ => Env </env>

  rule <thread>...
         <k> spawn S => !T:Int ...</k>
         <env> Env </env>
         <crntObj> Obj </crntObj>
       ...</thread>
       (.Bag => <thread>...
               <k> S </k>
               <env> Env </env>
               <id> !T </id>
               <crntObj> Obj </crntObj>
             ...</thread>)

  rule <k> class Class1 extends Class2 { S } => .K ...</k>
       <classes>... (.Bag => <classData>
                            <className> Class1 </className>
                            <baseClass> Class2 </baseClass>
                            <declarations> S </declarations>
                        </classData>)
       ...</classes>

  rule <k> T:Type F:Id(Ps:Params) S => .K ...</k>
       <crntClass> C </crntClass>
       <location> OL </location>
       <env> Env => Env[F <- L] </env>
       <store>... .Map => L|->methodClosure(getTypes(Ps)->T,C,OL,Ps,S) ...</store>
       <nextLoc> L => L +Int 1 </nextLoc>

  syntax KItem ::= envStackFrame(Id, Map)

  rule <k> new Class:Id(Vs:Vals) ~> K
           => create(Class) ~> (storeObj ~> ((Class(Vs)); return this;)) </k>
       <env> Env => .Map </env>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
     //<br/> // TODO(KORE): support latex annotations #1799
       <control>
         <xstack> XS </xstack>
         <crntObj> Obj
                   => <crntClass> Object </crntClass>
                      <envStack> ListItem(envStackFrame(Object, .Map)) </envStack>
                      <location> L </location>
         </crntObj>
         <returnType> T => Class </returnType>
         <fstack> .List => ListItem(fstackFrame(Env, K, XS, T, <crntObj>Obj</crntObj>)) ...</fstack>
       </control>

  syntax KItem ::= create(Id)

  rule <k> create(Class:Id)
           => create(Class1) ~> setCrntClass(Class) ~> S ~> addEnvLayer ...</k>
       <className> Class </className>
       <baseClass> Class1:Id </baseClass>
       <declarations> S </declarations>

  rule <k> create(Object) => .K ...</k>

  syntax KItem ::= setCrntClass(Id)

  rule <k> setCrntClass(C) => .K ...</k>
       <crntClass> _ => C </crntClass>

  syntax KItem ::= "addEnvLayer"

  rule <k> addEnvLayer => .K ...</k>
       <env> Env => .Map </env>
       <crntClass> Class:Id </crntClass>
       <envStack> .List => ListItem(envStackFrame(Class, Env)) ...</envStack>

  syntax KItem ::= "storeObj"

  rule <k> storeObj => .K ...</k>
       <crntObj>
         <crntClass> Class </crntClass>
         <envStack> EStack </envStack>
         (<location> L:Int </location> => .Bag)
       </crntObj>
       <store>... .Map => L |-> objectClosure(Class, EStack) ...</store>

  rule <k> this => objectClosure(Class, EStack) ...</k>
       <crntObj>
         <crntClass> Class </crntClass>
         <envStack> EStack </envStack>
         ...
       </crntObj>

  rule <k> X:Id => this . X ...</k> <env> Env:Map </env>
    requires notBool(X in keys(Env))

  context HOLE . _::Id requires (HOLE =/=K super)

/*  rule objectClosure(<crntObj> <crntClass> Class:Id </crntClass>
                     <envStack>... ListItem((Class,EnvC:EnvCell)) EStack </envStack> </crntObj>)
       . X:Id
    => lookupMember(<envStack> ListItem((Class,EnvC)) EStack </envStack>, X) */
  rule objectClosure(Class:Id,
                     ListItem(envStackFrame(Class,Env)) EStack)
       . X:Id
    => lookupMember(ListItem(envStackFrame(Class,Env)) EStack, X)
  rule objectClosure(Class:Id,
                     (ListItem(envStackFrame(Class':Id,_)) => .List) _EStack)
       . _X:Id
    requires Class =/=K Class'

/*  rule <k> super . X => lookupMember(<envStack>EStack</envStack>, X) ...</k>
       <crntClass> Class </crntClass>
       <envStack>... ListItem((Class,EnvC:EnvCell)) EStack </envStack> */
  rule <k> super . X => lookupMember(EStack, X) ...</k>
       <crntClass> Class:Id </crntClass>
       <envStack> ListItem(envStackFrame(Class,_)) EStack </envStack>
  rule <k> super . _X ...</k>
       <crntClass> Class:Id </crntClass>
       <envStack> (ListItem(envStackFrame(Class':Id,_)) => .List) _EStack </envStack>
    requires Class =/=K Class'

  rule <k> (X:Id => V)(_:Exps) ...</k>
       <env>... X |-> L ...</env>
       <store>... L |-> V:Val ...</store>

  rule <k> (X:Id => this . X)(_:Exps) ...</k>
       <env> Env </env>
    requires notBool(X in keys(Env))

  context HOLE._::Id(_) requires HOLE =/=K super

  // HW5 Exercise 2: like in Java, a private method of the current class is
  // not dynamically dispatched (see lookupMethod at the end)
  rule <k> (objectClosure(C, EStack) . X
            => lookupMethod(C, EStack, X:Id, CC, P))(_:Exps) ...</k>
       <crntClass> CC </crntClass> <privates> P </privates>

/*  rule <k> (super . X
            => lookupMember(<envStack>EStack</envStack>,X))(_:Exps)...</k>
       <crntClass> Class </crntClass>
       <envStack>... ListItem((Class,_)) EStack </envStack> */
  rule <k> (super . X
            => lookupMember(EStack,X))(_:Exps)...</k>
       <crntClass> Class:Id </crntClass>
       <envStack> ListItem(envStackFrame(Class,_)) EStack </envStack>
  rule <k> (super . _X)(_:Exps)...</k>
       <crntClass> Class:Id </crntClass>
       <envStack> (ListItem(envStackFrame(Class':Id,_)) => .List) _EStack </envStack>
    requires Class =/=K Class'

  // TODO(KORE): fix getKLabel #1801
  rule (A:Exp(B:Exps))(C:Exps) => A(B) ~> #freezerFunCall(C)
  rule (A:Exp[B:Exps])(C:Exps) => A[B] ~> #freezerFunCall(C)
  rule V:Val ~> #freezerFunCall(C:Exps) => V(C)
  syntax KItem ::= "#freezerFunCall" "(" K ")"
  /*
  context HOLE(_:Exps)
    requires getKLabel HOLE ==KLabel '_`(_`) orBool getKLabel HOLE ==KLabel '_`[_`]
  */

  rule <k> (lookup(L) => V)(_:Exps) ...</k>  <store>... L |-> V:Val ...</store>

  rule objectClosure(_, ListItem(envStackFrame(C,_)) _)
       instanceOf C => true

  rule objectClosure(_, (ListItem(envStackFrame(C::Id,_)) => .List) _)
       instanceOf C'  requires C =/=K C'

  rule objectClosure(_, .List) instanceOf _ => false

  rule (C:Id) objectClosure(Irrelevant, EStack)
    => objectClosure(Irrelevant, EStack) instanceOf C ~> true?
       ~> objectClosure(C, EStack)

  rule <k> lvalue(X:Id => this . X) ...</k>  <env> Env </env>
    requires notBool(X in keys(Env))

  context lvalue((HOLE . _)::Exp)

/*  rule lvalue(objectClosure(<crntObj> <crntClass> C </crntClass>
                            <envStack>... ListItem((C,EnvC:EnvCell)) EStack </envStack> </crntObj>)
              . X
              => lookupMember(<envStack> ListItem((C,EnvC)) EStack </envStack>,
                              X)) */
  rule lvalue(objectClosure(C:Id,
                            ListItem(envStackFrame(C,Env)) EStack)
              . X
              => lookupMember(ListItem(envStackFrame(C,Env)) EStack,
                              X))
  rule lvalue(objectClosure(C,
                            (ListItem(envStackFrame(C',_)) => .List) _EStack)
              . _X)
    requires C =/=K C'

  syntax Exp ::= lookupMember(List,Id)  [function]

  // HW5 Exercise 2: remember the class whose layer holds the member, so that
  // the access can be checked before the location is looked up
  rule lookupMember(ListItem(envStackFrame(C, X |-> L _)) _, X) => access(C, L)

  // TODO: fix rule below as shown once we support functions with deep rewrites
  // rule lookupMember(<envStack> ListItem((_, <env> Env </env>)) => .List
  //                     ...</envStack>, X)
  //   requires notBool(X in keys(Env))
  rule lookupMember(ListItem(envStackFrame(_, Env)) L, X)
    => lookupMember(L, X)
    requires notBool(X in keys(Env))

  rule typeOf(objectClosure(C,_)) => C
  rule typeOf(methodClosure(T:Type,_,_,_Ps:Params,_)) => T

  syntax Exp ::= subtype(Types,Types)

  rule subtype(T:Type, T) => true

  rule <k> subtype(C1:Id, C:Id) => subtype(C2, C) ...</k>
       <className> C1 </className>
       <baseClass> C2:Id </baseClass>
    requires C1 =/=K C

  rule subtype(Object,Class:Id) => false
    requires Class =/=K Object

  rule subtype(Ts1->T2,Ts1'->T2') => subtype(((T2)::Type,Ts1'),((T2')::Type,Ts1))

// Note that the following rule would be wrong!
//  rule subtype(T[],T'[]) => subtype(T,T')

  rule subtype((T:Type,Ts),(T':Type,Ts')) => subtype(T,T') && subtype(Ts,Ts')
    requires Ts =/=K .Types
  rule subtype(.Types,.Types) => true

  syntax Val ::= unsafeCast(Val,Type)  [function]

  rule unsafeCast(objectClosure(_,EStack), C:Id)
    => objectClosure(C,EStack)

  rule unsafeCast(methodClosure(_T',C,OL,Ps,S), T) => methodClosure(T,C,OL,Ps,S)

  rule unsafeCast(V:Val, T:Type) => V  requires typeOf(V) ==K T

  syntax KItem ::= "true?"
  rule true ~> true? => .K

// HW5 Exercise 2: private members.
// A private declaration is executed like a public one; afterwards the
// location just bound to the member name is recorded in <privates>.
  syntax KItem ::= markPrivate(Id)
  rule private T:Type X:Id; => T X; ~> markPrivate(X)
  rule private T:Type X:Id[Es:Exps]; => T X[Es]; ~> markPrivate(X)
  rule private T:Type F:Id(Ps:Params) S => T F(Ps) S ~> markPrivate(F)
  rule <k> markPrivate(X) => .K ...</k>
       <env>... X |-> L ...</env>
       <privates> P => P SetItem(L) </privates>

// access(C, L): member at location L found in the layer of class C.  A
// private member may only be accessed from code of class C (the current
// class), possibly in another object; otherwise execution gets stuck.
  syntax Exp ::= access(Id, Int)
  syntax Bool ::= canAccess(Id, Int, Id, Set)  [function]
  rule canAccess(C, L, CC, P) => notBool(L in P) orBool C ==K CC

  rule <k> access(C, L) => lookup(L) ...</k>
       <crntClass> CC </crntClass> <privates> P </privates>
    requires canAccess(C, L, CC, P)
  rule <k> (access(C, L) => lookup(L))(_:Exps) ...</k>
       <crntClass> CC </crntClass> <privates> P </privates>
    requires canAccess(C, L, CC, P)
  rule <k> lvalue(access(C, L) => lookup(L)) ...</k>
       <crntClass> CC </crntClass> <privates> P </privates>
    requires canAccess(C, L, CC, P)

// Method invocation o.X(...), where o has (static) class C and the code runs
// in class CC.  Look X up statically, starting with the layer of C.  If it
// is found in the layer of CC and it is private there, then it is the
// method meant by the code (Java: private methods are not overridden), so
// it is bound statically.  Otherwise X is dynamically dispatched, starting
// with the instance class, as before; the access check is done afterwards.
  syntax Exp ::= lookupMethod(Id, List, Id, Id, Set)  [function]
               | bindMethod(Exp, List, Id, Id, Set)    [function]
               | findMember(List, Id)                  [function]
               | "noMember"
  syntax List ::= layersFrom(Id, List)  [function]

  rule lookupMethod(C, EStack, X, CC, P)
    => bindMethod(findMember(layersFrom(C, EStack), X), EStack, X, CC, P)

  rule bindMethod(access(CC, L), _, _, CC, P) => access(CC, L)  requires L in P
  rule bindMethod(_, EStack, X, _, _) => lookupMember(EStack, X)  [owise]

  rule findMember(ListItem(envStackFrame(C, X |-> L _)) _, X) => access(C, L)
  rule findMember(ListItem(envStackFrame(_, Env)) EStack, X) => findMember(EStack, X)
    requires notBool(X in keys(Env))
  rule findMember(.List, _) => noMember

  rule layersFrom(C, ListItem(envStackFrame(C, Env)) EStack)
    => ListItem(envStackFrame(C, Env)) EStack
  rule layersFrom(C, ListItem(envStackFrame(C', _)) EStack) => layersFrom(C, EStack)
    requires C =/=K C'
  rule layersFrom(_, .List) => .List
endmodule
