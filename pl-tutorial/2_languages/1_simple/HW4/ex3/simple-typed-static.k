// Copyright (c) Runtime Verification, Inc. All Rights Reserved.
// CS422 HW4 Exercise 3: code extracted from the tutorial's literate simple-typed-static.md;
// all changes are marked "HW4 Exercise 3".

module SIMPLE-TYPED-STATIC-SYNTAX
  imports DOMAINS-SYNTAX

  syntax Id ::= "main" [token]

  syntax Type ::= "void" | "int" | "bool" | "string"
                | Type "[" "]"
                | "(" Type ")"             [bracket]
                > Types "->" Type
// HW4 Exercise 3: function types may also say which exception types the
// function may throw, e.g. int->int throws bool.  A function type without
// a throws clause throws nothing.
                | Types "->" Type "throws" Types

  syntax Types ::= List{Type,","}          [overload(exps)]

  syntax Param ::= Type Id
  syntax Params ::= List{Param,","}

  syntax Stmt ::= Type Exps ";"
                | Type Id "(" Params ")" Block
// HW4 Exercise 3: functions may declare the exceptions they can throw
                | Type Id "(" Params ")" "throws" Types Block

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
                 Exp "&&" Exp            [strict, left]
               | Exp "||" Exp            [strict, left]
               > "spawn" Block
               > Exp "=" Exp             [strict(2), right]

  syntax Exps ::= List{Exp,","}          [strict, overload(exps)]

  syntax Block ::= "{" "}"
                | "{" Stmt "}"

  syntax Stmt ::= Block
                | Exp ";"                                  [strict]
                | "if" "(" Exp ")" Block "else" Block      [avoid, strict]
                | "if" "(" Exp ")" Block                   [macro]
                | "while" "(" Exp ")" Block                [strict]
                | "for" "(" Stmt Exp ";" Exp ")" Block     [macro]
                | "return" Exp ";"                         [strict]
                | "return" ";"
                | "print" "(" Exps ")" ";"                 [strict]
                | "try" Block "catch" "(" Param ")" Block
                | "throw" Exp ";"                          [strict]
                | "join" Exp ";"                           [strict]
                | "acquire" Exp ";"                        [strict]
                | "release" Exp ";"                        [strict]
                | "rendezvous" Exp ";"                     [strict]

  syntax Stmt ::= Stmt Stmt                             [seqstrict, right]

  rule if (E) S => if (E) S else {}
  rule for(Start Cond; Step) {S:Stmt} => {Start while(Cond){S Step;}}
  rule for(Start Cond; Step) {} => {Start while(Cond){Step;}}
  rule T:Type E1:Exp, E2:Exp, Es:Exps; => T E1; T E2, Es;               [anywhere]
  rule T:Type X:Id = E; => T X; X = E;                                  [anywhere]

endmodule


module SIMPLE-TYPED-STATIC
  imports SIMPLE-TYPED-STATIC-SYNTAX
  imports DOMAINS

  syntax Exp ::= Type
  syntax Exps ::= Types
  syntax BlockOrStmtType ::= "block" | "stmt"
  syntax Type ::= BlockOrStmtType
  syntax Block ::= BlockOrStmtType
  syntax KResult ::= Type
                   | Types    //TODO: remove this, eventually

  configuration <T color="yellow">
                  <tasks color="orange">
                    <task multiplicity="*" color="yellow" type="Set">
                      <k color="green"> $PGM:Stmt </k>
                      <tenv multiplicity="?" color="cyan"> .Map </tenv>
                      <returnType multiplicity="?" color="black"> void </returnType>
                      <allowed multiplicity="?" color="red"> .Set </allowed>
                    </task>
                  </tasks>
//                  <br/>
                  <gtenv color="blue"> .Map </gtenv>
                </T>

  rule <task> <k> T:Type X:Id; => stmt ...</k> </task>
       <gtenv> Rho (.Map => X |-> T) </gtenv>
    requires notBool(X in keys(Rho))
  rule <k> T:Type X:Id; => stmt ...</k> <tenv> Rho => Rho[X <- T] </tenv>

  context _:Type _::Exp[HOLE::Exps];
// The rule below may need to sort E to Exp in the future, if the
// parser gets stricter; without that information, it may not be able
// to complete the LHS into T E[int,Ts],.Exps; (and similarly for the RHS)
  rule T:Type E:Exp[int,Ts:Types]; => T[] E[Ts];
// I want to write the rule below as _:Type (E:Exp[.Types] => E),
// but the list completion seems to not work well with that.
  rule T:Type E:Exp[.Types]; => T E;

// HW4 Exercise 3: each local task has an <allowed> cell: the set of
// exception types that may be thrown at this point, because an enclosing
// try-catch of that type catches them or because the function declares
// them in its throws clause.  A function without throws clause allows
// nothing; one with "throws Es" allows Es, and its type records Es.
  rule <task> <k> T:Type F:Id(Ps:Params) S => getTypes(Ps)->T F; ...</k> </task>
       (.Bag => <task>
               <k> mkDecls(Ps) S </k> <tenv> .Map </tenv> <returnType> T </returnType>
               <allowed> .Set </allowed>
             </task>)
  rule <task> <k> T:Type F:Id(Ps:Params) throws Es:Types S
                  => (getTypes(Ps) -> T throws Es) F; ...</k> </task>
       (.Bag => <task>
               <k> mkDecls(Ps) S </k> <tenv> .Map </tenv> <returnType> T </returnType>
               <allowed> toSet(Es) </allowed>
             </task>)

  rule <task> <k> stmt => main(.Exps); </k>
       (.Bag => <tenv> .Map </tenv> <allowed> .Set </allowed>) </task>

  rule <task>... <k> _:BlockOrStmtType </k> <tenv> _ </tenv> ...</task> => .Bag

  rule _:Int => int
  rule _:Bool => bool
  rule _:String => string

  rule <k> X:Id => T ...</k> <tenv>... X |-> T ...</tenv>

  rule <k> X:Id => T ...</k> <tenv> Rho </tenv> <gtenv>... X |-> T ...</gtenv>
    requires notBool(X in keys(Rho))

  rule <task> <k> X:Id => T ...</k> </task> <gtenv>... X |-> T ...</gtenv>

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

// NOTE:
// We used to need parentheses in the RHS, to avoid capturing Ts as an attribute
// Let's hope that is not a problem anymore.

  rule (T[])[int, Ts:Types] => T[Ts]
  rule T:Type[.Types] => T

  rule sizeOf(_T[]) => int

  rule read() => int

  rule print(T:Type, Ts => Ts); requires T ==K int orBool T ==K string
  rule print(.Types); => stmt

  context (HOLE => ltype(HOLE)) = _
  rule T:Type = T => T

  rule (Ts:Types -> T)(Ts) => T requires Ts =/=K .Types
  rule (void -> T)(.Types) => T
// HW4 Exercise 3: calling a function that may throw Es is allowed only
// where all of Es may be thrown.
  rule <k> (Ts:Types -> T throws Es)(Ts) => T ...</k> <allowed> A </allowed>
    requires Ts =/=K .Types andBool allIn(Es, A)
  rule <k> (void -> T throws Es)(.Types) => T ...</k> <allowed> A </allowed>
    requires allIn(Es, A)

  rule <k> return T:Type; => stmt ...</k> <returnType> T </returnType>
  rule <k> return; => stmt ...</k> <returnType> _ </returnType>

  rule {} => block

  rule <task> <k> {S} => block ...</k> <tenv> Rho </tenv> R </task>
       (.Bag => <task> <k> S </k> <tenv> Rho </tenv> R </task>)

  rule _:Type; => stmt

  rule if (bool) block else block => stmt
  rule while (bool) block => stmt

// HW4 Exercise 3: exceptions of any type.  The try block is checked in a
// new task where the catch type T is also allowed; the catch block is
// checked in the current task (exceptions thrown there go outward).
// A throw of type T is accepted only if T is allowed; otherwise it could
// escape uncaught, and type checking gets stuck.
  rule <task> <k> try S1 catch(T:Type X:Id) S2 => {T X; S2} ...</k>
         <tenv> Rho </tenv> <allowed> A </allowed> R
       </task>
       (.Bag => <task> <k> S1 </k>
                  <tenv> Rho </tenv> <allowed> A SetItem(T) </allowed> R
                </task>)
  rule <k> throw T:Type; => stmt ...</k> <allowed>... SetItem(T) ...</allowed>

  syntax Bool ::= allIn(Types, Set)  [function]
  rule allIn(.Types, _) => true
  rule allIn((T:Type, Ts:Types), A) => (T in A) andBool allIn(Ts, A)
  syntax Set ::= toSet(Types)  [function]
  rule toSet(.Types) => .Set
  rule toSet(T:Type, Ts:Types) => SetItem(T) toSet(Ts)

  rule <k> spawn S => int ...</k> <tenv> Rho </tenv>
       (.Bag => <task> <k> S </k> <tenv> Rho </tenv> <allowed> .Set </allowed> </task>)
  rule join int; => stmt
  rule acquire _:Type; => stmt
  rule release _:Type; => stmt
  rule rendezvous _:Type; => stmt

  rule _:BlockOrStmtType _:BlockOrStmtType => stmt

  syntax Stmt ::= mkDecls(Params)  [function]
  rule mkDecls(T:Type X:Id, Ps:Params) => T X; mkDecls(Ps)
  rule mkDecls(.Params) => {}

  syntax LValue ::= Id
  rule isLValue(_:Exp[_:Exps]) => true
  syntax Exp ::= LValue  // K should be able to infer this
                         // if not added, then it gets stuck with an Id on k cell

// Instead of the second LValue production above you can use a rule:
//  rule isLValue(_:Exp[_:Exps]) => true

  syntax Exp ::= ltype(Exp)
//  context ltype(HOLE:LValue)
// The above context does not work due to some error, so we write instead
  context ltype(HOLE) requires isLValue(HOLE)

  syntax Types ::= getTypes(Params)  [function]
  rule getTypes(T:Type _:Id) => T, .Types   // I would like to not use .Types
  rule getTypes(T:Type _:Id, P, Ps) => T, getTypes(P,Ps)
  rule getTypes(.Params) => void, .Types

endmodule

