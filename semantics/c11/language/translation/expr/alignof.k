module C-EXPR-ALIGNOF
     imports C-ABSTRACT-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-EXPR-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule (.K => typeof(E)) ~> AlignofExpression(E:K)
     rule typeof(T:Type) ~> AlignofExpression(_) => alignofType(T)
     rule AlignofType(T:Type, K:K) => alignofType(DeclType(T, K))

     syntax KItem ::= alignofType(K) [strict]
     rule alignofType(T:Type) => tv(getAlignas(T), ut(SetItem(IntegerConstant), cfg:sizeut))
          requires isCompleteType(T) andBool notBool isFunctionType(T)
     rule (.K => CV("TAL1", "Trying to compute alignof of a type that is incomplete or a function type.", "6.5.3.4:1"))
          ~> alignofType(T:Type)
          requires notBool isCompleteType(T) orBool isFunctionType(T)
endmodule

