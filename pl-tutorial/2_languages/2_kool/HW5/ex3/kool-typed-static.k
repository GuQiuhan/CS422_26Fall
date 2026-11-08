// Copyright (c) Runtime Verification, Inc. All Rights Reserved.
// CS422 HW5 Exercise 3: code extracted from the tutorial's literate kool-typed-static.md;
// all changes are marked "HW5 Exercise 3".

module KOOL-TYPED-STATIC-SYNTAX
  imports DOMAINS-SYNTAX

  syntax Id ::= "Object" [token] | "Main" [token]

  syntax Type ::= "void" | "int" | "bool" | "string"
                | Id                     [klabel("class"), symbol, avoid]  // see next
                | Type "[" "]"
                | "(" Type ")"           [bracket]
                > Types "->" Type

  syntax Types ::= List{Type,","}        [overload(exps)]

  syntax Param ::= Type Id
  syntax Params ::= List{Param,","}

  syntax Stmt ::= Type Exps ";" [avoid]
                | Type Id "(" Params ")" Block
                // HW5 Exercise 3: optional "private" before member declarations
                | "private" Type Exps ";"
                | "private" Type Id "(" Params ")" Block
                | "class" Id Block
                | "class" Id "extends" Id Block

  syntax FieldReference ::= Exp "." Id          [strict(1)]
  syntax ArrayReference ::= Exp "[" Exps "]"    [strict]

  syntax Exp ::= Int | Bool | String | Id
               | "this"
               | "super"
               | "(" Exp ")"             [bracket]
               | "++" Exp
               | Exp "instanceOf" Id     [strict(1)]
               | "(" Id ")" Exp          [strict(2)]
               | "new" Id "(" Exps ")"   [strict(2)]
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
                 Exp "&&" Exp            [strict, left]
               | Exp "||" Exp            [strict, left]
               > "spawn" Block  // not strict: to check return and exceptions
               > Exp "=" Exp             [strict(2), right]

  syntax Exp ::= FieldReference | ArrayReference
  syntax priority _.__KOOL-TYPED-STATIC-SYNTAX > _[_]_KOOL-TYPED-STATIC-SYNTAX > _(_)_KOOL-TYPED-STATIC-SYNTAX

  syntax Exps ::= List{Exp,","}          [strict, overload(exps)]

  syntax Block ::= "{" "}"
                | "{" Stmt "}"

  syntax Stmt ::= Block
                | Exp ";"                                 [strict]
                | "if" "(" Exp ")" Block "else" Block     [avoid, strict]
                | "if" "(" Exp ")" Block                  [macro]
                | "while" "(" Exp ")" Block               [strict]
                | "for" "(" Stmt Exp ";" Exp ")" Block    [macro]
                | "return" Exp ";"                        [strict]
                | "return" ";"
                | "print" "(" Exps ")" ";"                [strict]
                | "try" Block "catch" "(" Param ")" Block [strict(1)]
                | "throw" Exp ";"                         [strict]
                | "join" Exp ";"                          [strict]
                | "acquire" Exp ";"                       [strict]
                | "release" Exp ";"                       [strict]
                | "rendezvous" Exp ";"                    [strict]

  syntax Stmt ::= Stmt Stmt                            [seqstrict, right]

  rule if (E) S => if (E) S else {}
  rule for(Start Cond; Step) {S:Stmt} => {Start while(Cond){S Step;}}
  rule T:Type E1:Exp, E2:Exp, Es:Exps; => T E1; T E2, Es;               [anywhere]
  rule T:Type X:Id = E; => T X; X = E;                                  [anywhere]
  // HW5 Exercise 3: the same desugaring for private fields
  rule private T:Type E1:Exp, E2:Exp, Es:Exps; => private T E1; private T E2, Es;  [anywhere]
  rule private T:Type X:Id = E; => private T X; X = E;                                [anywhere]

  rule class C:Id S => class C extends Object S

endmodule

module KOOL-TYPED-STATIC
  imports KOOL-TYPED-STATIC-SYNTAX
  imports DOMAINS

  configuration <T multiplicity="?" color="yellow">
                  <tasks color="orange" multiplicity="?">
                    <task multiplicity="*" color="yellow" type="Set">
                      <k color="green"> $PGM:Stmt </k>
                      <tenv multiplicity="?" color="cyan"> .Map </tenv>
                      <ctenvT multiplicity="?" color="blue"> .Map </ctenvT>
                      <returnType multiplicity="?" color="black"> void </returnType>
                      <inClass multiplicity="?" color="Fuchsia"> .K </inClass>
                    </task>
                  </tasks>
//                  <br/>
                  <classes color="Fuchsia">
                    <classData multiplicity="*" type="Map">
                      <className color="Fuchsia"> Object </className>
                      <baseClass color="Fuchsia"> .K </baseClass>
                      <baseClasses color="Fuchsia"> .Set </baseClasses>
                      <ctenv multiplicity="?" color="blue"> .Map </ctenv>
                      <privates> .Set </privates>  // HW5 Exercise 3: private member names
                    </classData>
                  </classes>
                </T>
                <output color="brown" stream="stdout"> .List </output>

  syntax Exp ::= Type
  syntax Exps ::= Types
  syntax BlockOrStmtType ::= "block" | "stmt"
  syntax Type ::= BlockOrStmtType
  syntax Block ::= BlockOrStmtType
  syntax KResult ::= Type
                   | Types  // TODO: should not be needed


  context _:Type _::Exp[HOLE::Exps];

  rule T:Type E:Exp[int,Ts:Types]; => T[] E[Ts];
  rule T:Type E:Exp[.Types]; => T E;


  rule <task>... <k> _:BlockOrStmtType </k> <tenv> _ </tenv> ...</task> => .Bag


  rule _:Int => int
  rule _:Bool => bool
  rule _:String => string


  rule <k> X:Id => T ...</k> <tenv>... X |-> T ...</tenv>


  context ++(HOLE => ltype(HOLE))
  rule ++ int => int
  rule int + int => int
  rule string + string => string
  rule int - int => int
  rule int * int => int
  rule int / int => int
  rule int % int => int
  rule - int => int
  rule int < int => bool
  rule int <= int => bool
  rule int > int => bool
  rule int >= int => bool
  rule T:Type == T => bool
  rule T:Type != T => bool
  rule bool && bool => bool
  rule bool || bool => bool
  rule ! bool => bool


  rule (T[])[int, Ts:Types] => T[Ts]
  rule T:Type[.Types] => T

  rule sizeOf(_T[]) => int


  rule read() => int

  rule print(T:Type, Ts => Ts); requires T ==K int orBool T ==K string
  rule print(.Types); => stmt


  context (HOLE => ltype(HOLE)) = _


  rule <k> return; => stmt ...</k> <returnType> _ </returnType>


  rule {} => block

  rule <task> <k> {S:Stmt} => block ...</k> <tenv> Rho </tenv> R </task>
       (.Bag => <task> <k> S </k> <tenv> Rho </tenv> R </task>)

  rule _:Type; => stmt
  rule if (bool) block else block => stmt
  rule while (bool) block => stmt

  rule join int; => stmt
  rule acquire _:Type; => stmt
  rule release _:Type; => stmt
  rule rendezvous _:Type; => stmt

  syntax Stmt ::= BlockOrStmtType
  rule _:BlockOrStmtType _:BlockOrStmtType => stmt

  syntax Stmt ::= mkDecls(Params)  [function]
  rule mkDecls(T:Type X:Id, Ps:Params) => T X; mkDecls(Ps)
  rule mkDecls(.Params) => {}

  syntax LValue ::= Id
                  | FieldReference
                  | ArrayReference
  syntax Exp ::= LValue

  syntax Exp ::= ltype(Exp)
// We would like to say:
//  context ltype(HOLE:LValue)
// but we currently cannot type the HOLE
  context ltype(HOLE) requires isLValue(HOLE)

// OLD approach:
//  syntax Exp ::= ltype(Exp)  [function]
//  rule ltype(X:Id) => X
//  rule ltype(E:Exp [Es:Exps]) => E[Es]

  syntax Types ::= getTypes(Params)  [function]
  rule getTypes(T:Type _:Id) => T, .Types
  rule getTypes(T:Type _:Id, P, Ps) => T, getTypes(P,Ps)
  rule getTypes(.Params) => void, .Types

  rule <k> T:Type X:Id; => checkType(T) ~> stmt ...</k>
       <tenv> Rho => Rho[X <- T] </tenv>

  rule <k> T:Type X:Id; => checkType(T) ~> stmt ...</k>
       <ctenvT> Rho (.Map => X |-> T) </ctenvT>
    requires notBool(X in keys(Rho))

  rule <k> T:Type X:Id; => stuck(T X;) ...</k>
       <ctenvT>... X |-> _ ...</ctenvT>
       <inClass> C:Id </inClass>
//       <br/>
       <output>... .List => ListItem("Member \"" +String Id2String(X)
                              +String "\" declared twice in class \""
                              +String Id2String(C) +String "\"!\n") </output>

  rule <k> T:Type F:Id(Ps:Params) S
        => checkMethod(F, getTypes(Ps)->T, C')
           ~> getTypes(Ps)->T F; ...</k>
//       <br/>
       <inClass> C </inClass>
       <ctenvT> _ </ctenvT> // to ensure we are in a class pass
       <className> C </className>
       <baseClass> C' </baseClass>
//       <br/>
       (.Bag => <task>
               <k> mkDecls(Ps) S </k>
               <inClass> C </inClass>
               <tenv> .Map </tenv>
               <returnType> T </returnType>
             </task>)

  rule T:Type = T':Type => checkSubtype(T', T) ~> T

  rule (Ts:Types -> T:Type) (Ts':Types) => checkSubtype(Ts',Ts) ~> T

  rule <k> return T:Type; => checkSubtype(T,T') ~> stmt ...</k>
       <returnType> T':Type </returnType>

  rule try block catch(T:Type X:Id) S => {T X; S}
  rule throw _T:Type ; => stmt

// explain why

  rule <k> spawn S:Block => int ...</k>
       <tenv> Rho </tenv>
       <inClass> C </inClass>
       (.Bag => <task>
               <k> S </k>
               <tenv> Rho </tenv>
               <inClass> C </inClass>
             </task>)

// There seems to be some error with the configuration concretization,
// as the rule below does not work when rewriting . to both the task
// and the class cells; I had to include two separate . rewrites

// TODO: the following fails krun; see #2117
  rule <task> <k> class C:Id extends C':Id { S:Stmt } => stmt ...</k> </task>
       (.Bag => <classData>...
               <className> C </className>
               <baseClass> C' </baseClass>
             ...</classData>)
//       <br/>
       (.Bag => <task>
                <k> checkType(`class`(C')) ~> S </k>
                <inClass> C </inClass>
                <ctenvT> .Map </ctenvT>
             </task>)

// You may want to try the thing below, but that failed, too
/*
syntax Type ::= "stmtStop"

  rule <tasks>...
       <task> <k> class C:Id extends C':Id { S:Stmt } => stmtStop ...</k> </task>
       (.Bag => <task>
                <k> checkType(`class`(C')) ~> S </k>
                <inClass> C </inClass>
                <ctenvT> .Map </ctenvT>
             </task>)
       ...</tasks>
       <classes>...
       .Bag => <classData>...
               <className> C </className>
               <baseClass> C' </baseClass>
             ...</classData>
       ...</classes>
//       <br/>
*/

  rule (<T>...
          <className> C </className>
          <className> C </className>
        ...</T> => .Bag)
       <output>... .List => ListItem("Class \"" +String Id2String(C)
                                  +String "\" declared twice!\n") </output>

  rule <baseClass> C </baseClass>
       <baseClasses> .Set => SetItem(C) </baseClasses>  [priority(25)]

  rule <classData>...
         <baseClasses> SetItem(C) Cs:Set (.Set => SetItem(C')) </baseClasses>
       ...</classData>
       <classData>... <className>C</className> <baseClass>C'</baseClass> ...</classData>
    requires notBool(C' in (SetItem(C) Cs))  [priority(25)]

  rule (<T>...
          <className> C </className>
          <baseClasses>... SetItem(C) ...</baseClasses>
        ...</T> => .Bag)
       <output>... .List => ListItem("Class \"" +String Id2String(C)
                                  +String "\" is in a cycle!\n") </output>
    [priority(25)]

  // HW5 Exercise 3: the constructor called by new runs in its own class (see
  // the dynamic semantics), so it may be private; ctorRef skips the check
  rule new C:Id(Ts:Types) => ctorRef(C) (Ts) ~> discard ~> `class`(C)

  rule <k> this => `class`(C) ...</k>
       <inClass> C:Id </inClass>

   rule <k> super => `class`(C') ...</k>
        <inClass> C:Id </inClass>
        <className> C </className>
        <baseClass> C':Id </baseClass>

  rule <k> X:Id => T ...</k>
       <ctenvT>... X |-> T ...</ctenvT>

  rule <k> X:Id => this . X ...</k>
       <tenv> Rho </tenv>
    requires notBool(X in keys(Rho))

// OLD approach:
//  rule ltype(E:Exp . X:Id) => E . X

  // HW5 Exercise 3: a private member of C is accessible only in class C
  rule <k> `class`(C:Id) . X:Id => T ...</k>
       <inClass> CC </inClass>
       <className> C </className>
       <ctenv>... X |-> T:Type ...</ctenv>
       <privates> P </privates>
    requires notBool(X in P) orBool C ==K CC
  rule <k> `class`(C:Id) . X:Id => stuck(`class`(C) . X) ...</k>
       <inClass> CC:Id </inClass>
       <className> C </className>
       <ctenv>... X |-> _:Type ...</ctenv>
       <privates>... SetItem(X) ...</privates>
       <output>... .List => ListItem("Private member \"" +String Id2String(X)
                              +String "\" of class \"" +String Id2String(C)
                              +String "\" cannot be accessed in class \""
                              +String Id2String(CC) +String "\"\n") </output>
    requires C =/=K CC

  rule <k> `class`(C1:Id => C2) . X:Id ...</k>
       <className> C1 </className>
       <baseClass> C2:Id </baseClass>
       <ctenv> Rho </ctenv>
    requires notBool(X in keys(Rho))

  rule <k> `class`(Object) . X:Id => stuck(`class`(Object) . X) ...</k>
       <inClass> C:Id </inClass>
//      <br/>
       <output>... .List => ListItem("Member \"" +String Id2String(X)
                              +String "\" not declared! (see class \""
                              +String Id2String(C) +String "\")\n") </output>

  rule `class`(_C1:Id) instanceOf _C2:Id => bool
  rule (C:Id) `class`(C) => `class`(C)
  rule <k> (C2:Id) `class`(C1:Id) => `class`(C2) ...</k>
       <className> C1 </className>
       <baseClasses>...SetItem(C2)...</baseClasses>    // upcast
  rule <k> (C2:Id) `class`(C1:Id) => `class`(C2) ...</k>
       <className> C2 </className>
       <baseClasses>...SetItem(C1)...</baseClasses>    // downcast
  rule <k> (C2) `class`(C1:Id) => stuck((C2) `class`(C1)) ...</k>
       <classData>...
         <className> C1 </className>
         <baseClasses> S1 </baseClasses>
       ...</classData>
       <classData>...
         <className> C2 </className>
         <baseClasses> S2 </baseClasses>
       ...</classData>
       <output>... .List => ListItem("Classes \"" +String Id2String(C1)
                              +String "\" and \"" +String Id2String(C2)
                              +String "\" are incompatible!\n") </output>
    requires notBool(C1 in S2) andBool notBool(C2 in S1)

// discard main task when done, issuing a "new main();" command to
// make sure that the class main and the method main() are declared.

  rule <task> <k> stmt => new Main(.Exps); </k>
              (.Bag => <tenv> .Map </tenv>
                    <returnType> void </returnType>
                    <inClass> Main </inClass>)
       </task>

// discard class task when done, adding a ctenv in class

  rule (<task>
          <k> stmt </k>
          <ctenvT> Rho </ctenvT>
          <inClass> C:Id </inClass>
        </task> => .Bag)
        <className> C </className>
        (.Bag => <ctenv> Rho </ctenv>)

// discard method task when done

  rule <task>...
         <k> stmt </k>
         <tenv> _ </tenv>  // only to ensure that this is a method task
       ...</task> => .Bag

// cleanup tasks and output a success message when done

  rule (<T>... <tasks> .Bag </tasks> ...</T> => .Bag)
       <output>... .List => ListItem("Type checked!\n") </output>

  syntax KItem ::= checkSubtype(Types,Types)

  rule checkSubtype(T:Type, T) => .K

  rule <k> checkSubtype(`class`(C:Id), `class`(C':Id)) => .K ...</k>
       <className> C </className>
       <baseClasses>... SetItem(C') ...</baseClasses>

  rule checkSubtype(Ts1->T2,Ts1'->T2')
    => checkSubtype(((T2)::Type,Ts1'),((T2')::Type,Ts1))

// note that the following rule would be wrong!
//  rule checkSubtype(T[],T'[]) => checkSubtype(T,T')

  rule checkSubtype((T:Type,Ts),(T':Type,Ts'))
    => checkSubtype(T,T') ~> checkSubtype(Ts,Ts')
    requires Ts =/=K .Types

  rule checkSubtype(.Types,.Types) => .K
  rule checkSubtype(.Types,void) => .K

  syntax KItem ::= checkType(Types)

  rule checkType(T:Type,Ts:Types) => checkType(T) ~> checkType(Ts)
    requires Ts =/=K .Types
  rule checkType(.Types) => .K
  rule checkType(int) => .K
  rule checkType(bool) => .K
  rule checkType(string) => .K
  rule checkType(void) => .K
  rule <k> checkType(`class`(C:Id)) => .K ...</k> <className> C </className>
  rule checkType(`class`(Object)) => .K
  rule checkType(Ts:Types -> T:Type) => checkType(T,Ts)
  rule checkType(T:Type[]) => checkType(T)

  syntax KItem ::= checkMethod(Id,Type,Id)

  rule <k> checkMethod(F:Id, T:Type, C:Id) => checkSubtype(T, T') ...</k>
       <className> C </className>
       <ctenv>... F |-> T':Type ...</ctenv>
       <privates> P </privates>          // HW5 Exercise 3
    requires notBool(F in P)
  // HW5 Exercise 3: a private method of a superclass is not overridden, so
  // its type does not constrain the new method
  rule <k> checkMethod(F:Id, _:Type, C:Id) => .K ...</k>
       <className> C </className>
       <ctenv>... F |-> _:Type ...</ctenv>
       <privates>... SetItem(F) ...</privates>

  rule <k> checkMethod(F:Id, _T:Type, (C:Id => C')) ...</k>
       <className> C </className>
       <baseClass> C':Id </baseClass>
       <ctenv> Rho </ctenv>
    requires notBool(F in keys(Rho))

  rule checkMethod(_:Id,_,Object) => .K

  syntax KItem ::= stuck(K)

  syntax KItem ::= "discard"
  rule _:KResult ~> discard => .K

// HW5 Exercise 3: private members.
// While the class is processed, the names of its private members are
// collected in the <privates> cell of the class.  Since <ctenv> is only
// added after the whole class has been processed, <privates> is complete
// whenever a member of the class can be looked up.
  syntax KItem ::= markPrivate(Id)
  rule private T:Type X:Id; => markPrivate(X) ~> T X;
  rule private T:Type X:Id[Es:Exps]; => markPrivate(X) ~> T X[Es];
  rule <k> private T:Type F:Id(Ps:Params) S
        => markPrivate(F) ~> checkPrivate(F, C, C') ~> T F(Ps) S ...</k>
       <inClass> C </inClass>
       <className> C </className>
       <baseClass> C' </baseClass>
  rule <k> markPrivate(X) => .K ...</k>
       <inClass> C </inClass>
       <className> C </className>
       <privates> P => P SetItem(X) </privates>

// checkPrivate(F, C, C'): method F of class C is private; reject it if the
// closest superclass (starting with C') declaring F declares it public.
// Otherwise dynamic dispatch could reach a private method from another class.
  syntax KItem ::= checkPrivate(Id, Id, Id)
  rule <k> checkPrivate(F, _, C') => .K ...</k>
       <className> C' </className>
       <ctenv>... F |-> _ ...</ctenv>
       <privates>... SetItem(F) ...</privates>
  rule <k> checkPrivate(F, C, C') => stuck(checkPrivate(F, C, C')) ...</k>
       <className> C' </className>
       <ctenv>... F |-> _ ...</ctenv>
       <privates> P </privates>
       <output>... .List => ListItem("Method \"" +String Id2String(F)
                              +String "\" cannot be private in class \"" +String Id2String(C)
                              +String "\" because it is public in class \""
                              +String Id2String(C') +String "\"\n") </output>
    requires notBool(F in P)
  rule <k> checkPrivate(F, _, (C' => C'')) ...</k>
       <className> C' </className>
       <baseClass> C'':Id </baseClass>
       <ctenv> Rho </ctenv>
    requires notBool(F in keys(Rho))
  rule checkPrivate(_, _, Object) => .K

// The constructor called by new C(...): looked up in C without the privacy
// check; if C declares no constructor, fall back to the usual lookup.
  syntax Exp ::= ctorRef(Id)
  rule <k> ctorRef(C) => T ...</k>
       <className> C </className>
       <ctenv>... C |-> T:Type ...</ctenv>
  rule <k> ctorRef(C) => `class`(C) . C ...</k>
       <className> C </className>
       <ctenv> Rho </ctenv>
    requires notBool(C in keys(Rho))
endmodule
