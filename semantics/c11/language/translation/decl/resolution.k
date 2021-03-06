module C-DECL-RESOLUTION-SYNTAX
     syntax KItem ::= "allocateIncompleteTentatives"
endmodule

module C-DECL-RESOLUTION
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-CONFIGURATION

     imports C-ERROR-SYNTAX

     syntax KItem ::= allocateIncompleteTentative(CId, K)

     rule <k> (.K => allocateIncompleteTentative(X, Decl))
               ~> allocateIncompleteTentatives
          ...</k>
          <externals>...
               (X:CId |-> Decl:K => .Map)
          ...</externals>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          [structural]
     rule <k> allocateIncompleteTentatives => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> .Map </externals>
          [structural]

     rule allocateIncompleteTentative(X:CId,
               declState(_,
                    t(Qs::Quals, Mods::Set, incompleteArrayType(T::Type)), declared, true))
          => declare(typedDeclaration(t(Qs, Mods, arrayType(T, 1)), X), NoInit())
          [structural]
     rule allocateIncompleteTentative(_,
               declState(_, t(_, Mods::Set, _), State:DeclState, _))
          => .K
          requires State =/=K declared
               // TODO(chathhorn): ... and we do this inline function check in
               // addition to completing tentatives.
               andBool notBool (State ==K completed andBool Inline() in Mods)
          [structural]
     rule allocateIncompleteTentative(_,
               declState(_, t(_, Mods::Set, _), _, false))
          => .K
          requires notBool (Inline() in Mods)
          [structural]
     rule allocateIncompleteTentative(X::CId,
               declState(_, t(_, Mods::Set, _), completed, _))
          => UNDEF("TDR1",
               "Declaration for inline function not defined in the same translation unit: "
               +String idToString(X) +String ".",
               "6.7.4:7, J.2:1 item 70")
          requires Inline() in Mods
          [structural]

endmodule
