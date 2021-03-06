module COMPAT-SYNTAX
     imports COMMON-SYNTAX

     imports ARRAY
     imports BASIC-K
     imports BOOL
     imports COLLECTIONS
     imports FLOAT
     imports INT
     imports K-EQUAL
     imports K-IO
     imports K-REFLECTION
     imports LIST
     imports MAP
     imports SET
     imports STRING

     syntax String ::= firstChar(String) [function]
     syntax String ::= nthChar(String, Int) [function]
     syntax String ::= butFirstChar(String) [function]

     syntax List ::= stringToList(String) [function]
     syntax String ::= listToString(List) [function]

     syntax String ::= idToString(CId) [function]

     syntax String ::= toUpperCase(String) [function]

     syntax Bool ::= all(List, K) [function]
     syntax Bool ::= some(List, K) [function]

     syntax List ::= removeListItem(List, K) [function]

     // TODO(chathhorn): ugly
     syntax KItem ::= toKRList(List)

     syntax KResult ::= krlist(List)

     syntax List ::= reverseList(List) [function]

     //TODO(liyi): syntax List ::= ListItem(Bag)
     syntax KItem ::= list(List)
     syntax KItem ::= map(Map)
     syntax KItem ::= set(Set)

     syntax K ::= listToK(List) [function]

     syntax KItem ::= kpair(K, K)

     syntax List ::= Int "to" Int [function]

     syntax List ::= times(Int, K) [function]

     syntax Set ::= filterSet(Set, K) [function]
     syntax List ::= filterList(List, K) [function]

     syntax Bool ::= some(Set, K) [function]

     //TODO(liyi): might not need this later
     syntax KItem ::= "dotK"
                    | lookup(Map, K) [function]

     syntax Bool ::= isKItem(K) [function]

     syntax Int ::= ceilDiv(Int, Int) [function]
     syntax List ::= mapList(List, K) [function]

     syntax SSList ::= toSSList(List) [function]
     syntax List ::= ofSSList(SSList) [function]

     syntax KItem ::= seqstrict(K)
endmodule

module COMPAT
     imports COMPAT-SYNTAX

     rule stringToList("") => .List
     rule stringToList(S:String)
               => ListItem(firstChar(S:String))
                    stringToList(butFirstChar(S:String))
          requires S:String =/=String ""

     rule listToString(.List) => ""
     rule listToString((ListItem(S:String) L:List))
               => S:String +String listToString(L:List)

     rule idToString(Identifier(S:String)) => S
     rule idToString(#NoName) => "<anonymous>"
     rule idToString(_) => "<unknown>" [owise]

     rule [firstChar]:
          firstChar(S:String) => substrString(S, 0, 1)

     rule [nthChar]:
          nthChar(S:String, N:Int) => substrString(S, N, N +Int 1)

     rule [butFirstChar]:
          butFirstChar(S:String)
          => substrString(S:String, 1, lengthString(S:String))

     rule all(ListItem(K:K) L:List, #klabel(Lbl:KLabel))
          => Lbl(K:K) andBool all(L, #klabel(Lbl))
     rule all(.List, _) => true

     rule some(ListItem(K:K) L:List, #klabel(Lbl:KLabel))
          => Lbl(K:K) orBool some(L, #klabel(Lbl))
     rule some(.List, _) => false

     rule toUpperCase(S:String)
          => toUpperCase(firstChar(S:String))
               +String toUpperCase(butFirstChar(S:String))
          requires lengthString(S) >Int 1

     rule toUpperCase(C:String)
          => C:String
          requires (lengthString(C) ==Int 1)
               andBool (ordChar(C) <Int ordChar("a")
                    orBool ordChar(C) >Int ordChar("z"))
     rule toUpperCase(C:String)
          => chrChar(absInt(ordChar(C)
               -Int (ordChar("a") -Int ordChar("A"))))
          requires (lengthString(C) ==Int 1)
               andBool (ordChar(C) >=Int ordChar("a")
                    andBool ordChar(C) <=Int ordChar("z"))

     rule removeListItem(.List, _) => .List
     rule removeListItem(ListItem(A:K) M:List, A) => M
     rule removeListItem(ListItem(A:K) M:List, A':K)
          => ListItem(A) removeListItem(M, A')
          requires A =/=K A'

     syntax Bool ::= subset(K, Set, Set) [function]

     rule subset(K:K, S1:Set, S2:Set) => S1 <=Set (S2 -Set SetItem(K))
          requires K in S2
     rule subset(K:K, _, S2:Set) => false
          requires notBool (K in S2)

     syntax Map ::= removeBagItemFromMap(Map, K) [function]
     rule removeBagItemFromMap(K |-> 1 M::Map, K:K) => M
     rule removeBagItemFromMap(K |-> I::Int M::Map, K:K) => K |-> (I -Int 1) M

     rule list(L:List) => toKRList(L)
          [structural]

     syntax KItem ::= "seqstrict()"
     rule seqstrict(list(HOLE:List)) => toSSList(HOLE) ~> seqstrict() [heat]
     rule HOLE:SSList ~> seqstrict() => seqstrict(krlist(ofSSList(HOLE))) [cool]

     syntax SSList ::= K "seqstrict::" SSList [seqstrict]
                     | ".SSList"
     rule isKResult(.SSList) => true
     rule isKResult(S1::SSList seqstrict:: S2::SSList) => isKResult(S1) andBool isKResult(S2)
     rule toSSList(ListItem(K:K) L::List) => K seqstrict:: toSSList(L)
     rule toSSList(.List) => .SSList
     rule ofSSList(krlist(L1::List) seqstrict:: L2::SSList) => L1 ofSSList(L2)
     rule ofSSList(.SSList) => .List
     rule ofSSList(K:K seqstrict:: L::SSList) => ListItem(K) ofSSList(L) [owise]

     syntax KItem ::= "toKRList'" "(" SubKRList ")" [strict]

     // TODO(dwightguth): refactor the below into a strict() operator
     syntax SubKRItem ::= sItem(K) [strict]
     syntax SubKRList ::= List{SubKRItem, "ss::"} [strict]
     syntax SubKRList ::= toSubKRList(List) [function]

     rule isKResult(.SubKRList) => true
     rule isKResult(S1::SubKRItem ss:: S2::SubKRList) => isKResult(S1) andBool isKResult(S2)

     syntax SubResult ::= srItem(K)
     syntax SubKRItem ::= SubResult
     syntax KResult ::= SubResult

     rule toSubKRList(.List) => .SubKRList
     rule toSubKRList(ListItem(K:K) L:List) => sItem(K) ss:: toSubKRList(L)

     // TODO(liyi): overcome the context associative matching
     //context toKRList'(_:List ListItem(HOLE) _:List)
     rule sItem(V:KResult) => srItem(V) [structural]

     rule toKRList(L:List) => toKRList'(toSubKRList(L)) ~> krlist(.List)
          [structural]

     rule toKRList'((srItem(V:KResult) ss:: S:SubKRList) => S)
          ~> krlist(_:List (.List => ListItem(V)))
          requires getKLabel(V) =/=K #klabel(`krlist`)
          [structural]
     // Somewhat contrived feature: nested lists are flattened.
     rule toKRList'((srItem(krlist(L:List)) ss:: S:SubKRList) => S)
          ~> krlist( _:List (.List => L))
          [structural]
     rule toKRList'(.SubKRList) => .K
          [structural]

     syntax List ::= reverseAppendList(List, List) [function]
     rule reverseAppendList(.List, L::List) => L
     rule reverseAppendList(ListItem(K:K) L::List, L2::List)
          => reverseAppendList(L, ListItem(K) L2)

     rule reverseList(L::List) => reverseAppendList(L, .List)

     rule listToK(ListItem(K:K) L:List) => K ~> listToK(L)
     rule listToK(.List) => .K

     rule N:Int to N => .List
     rule N:Int to N':Int => ListItem(N)  ((N +Int 1) to N')
          requires N <Int N'

     rule times(0, _) => .List
     rule times(N:Int, K:K) => ListItem(K) times(N -Int 1, K)
          requires N >Int 0

     rule filterSet(SetItem(K:K) S:Set, #klabel(Pred:KLabel))
          => #filterSet(K, S, #klabel(Pred))
     rule filterSet(.Set, _)
          => .Set

     syntax Set ::= #filterSet(K, Set, K) [function]
     rule #filterSet(K:K, .Set, #klabel(Pred:KLabel))
          => SetItem(K)
          requires Pred(K) ==K true
     rule #filterSet(K:K, .Set, #klabel(Pred:KLabel))
          => .Set
          requires Pred(K) =/=K true
     rule #filterSet(K:K, SetItem(K':K) S:Set, #klabel(Pred:KLabel))
          => SetItem(K) #filterSet(K', S, #klabel(Pred))
          requires Pred(K) ==K true
     rule #filterSet(K:K, SetItem(K':K) S:Set, #klabel(Pred:KLabel))
          => #filterSet(K', S, #klabel(Pred))
          requires Pred(K) =/=K true

     rule filterList(ListItem(K:K) L:List, #klabel(Pred:KLabel))
          => #filterList(K, L, #klabel(Pred))
     rule filterList(.List, _)
          => .List

     syntax List ::= #filterList(K, List, K) [function]
     rule #filterList(K:K, .List, #klabel(Pred:KLabel))
          => ListItem(K)
          requires Pred(K) ==K true
     rule #filterList(K:K, .List, #klabel(Pred:KLabel))
          => .List
          requires Pred(K) =/=K true
     rule #filterList(K:K, ListItem(K':K) L:List, #klabel(Pred:KLabel))
          => ListItem(K) #filterList(K', L, #klabel(Pred))
          requires Pred(K) ==K true
     rule #filterList(K:K, ListItem(K':K) L:List, #klabel(Pred:KLabel))
          => #filterList(K', L, #klabel(Pred))
          requires Pred(K) =/=K true

     rule some(S:Set, Lbl:K) => some'(.K, S, Lbl)

     syntax Bool ::= "some'" "(" K "," Set "," K ")" [function]
     rule some'(.K, SetItem(K:K) S:Set, Lbl:K) => some'(K, S, Lbl)
     rule some'(K:K, _, #klabel(Lbl:KLabel)) => true
          requires Lbl(K) ==K true
     rule some'(K:K, S:Set, #klabel(Lbl:KLabel)) => some'(.K, S, #klabel(Lbl))
          requires Lbl(K) =/=K true
               andBool (K =/=K .K)
     rule some'(.K, .Set, _) => false

     //TODO(liyi): might not need this
     rule dotK => .K [structural]
     rule lookup(Key |-> Val:K _:Map, Key:K) => Val

     rule isKItem(_:KItem) => true
     rule isKItem(_) => false [owise]

     rule ceilDiv(X:Int, Y:Int) => (X +Int Y -Int 1) /Int Y

     rule mapList(ListItem(K:K) L:List, #klabel(Lbl:KLabel)) => ListItem(Lbl(K)) mapList(L, #klabel(Lbl))
     rule mapList(.List, _) => .List
endmodule
