module C-STMT-IF-THEN
     imports C-ELABORATOR-SYNTAX
     imports C-EXPR-LOGICAL-SYNTAX
     imports C-SYNTAX
     imports C-TRANSLATION-ERROR-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule IfThenElse(C:RValue, TrueBr:K, FalseBr:K)
          => #if(simplifyTruth(C), TrueBr, FalseBr)

     syntax KItem ::= #if(K, K, K)
     context #if((HOLE:KItem => reval(HOLE)), _, _) [result(RValue)]
     rule (.K => elaborate(TrueBr, FalseBr)) ~> #if(_:RValue, TrueBr:K, FalseBr:K)
     rule <k> elaborateDone(TrueBr:K, FalseBr:K) ~> #if(C:RValue, _, _)
               => lintZero(C) ~> lintEmpty(TrueBr) // FalseBr empty when it's missing.
          ...</k>
          <elab>... .K => IfThenElse(C, TrueBr, FalseBr) </elab>

endmodule

