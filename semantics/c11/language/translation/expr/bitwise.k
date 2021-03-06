module C-EXPR-BITWISE
     imports C-ABSTRACT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     rule ~ te(K:K, T::UType) => te(~ K, T)
          requires isPromoted(T)

     rule te(L:K, T::UType) << tv(R:Int, T'::UType) => te(L << tv(R, T'), T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool R >=Int 0
               andBool R <Int bitSizeofType(T)
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
     rule tv(L:Int, T::UType) << te(R:K, T'::UType) => te(tv(L, T) << R, T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool L >=Int 0
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
     rule te(L:K, T::UType) << te(R:K, T'::UType) => te(L << R, T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))

     rule te(L:K, T::UType) >> tv(R:Int, T'::UType) => te(L >> tv(R, T'), T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool R >=Int 0
               andBool R <Int bitSizeofType(T)
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
     rule tv(L:Int, T::UType) >> te(R:K, T'::UType) => te(tv(L, T) >> R, T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool L >=Int 0
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))
     rule te(L:K, T::UType) >> te(R:K, T'::UType) => te(L >> R, T)
          requires isPromoted(T) andBool isPromoted(T')
               andBool notBool (fromConstantExpr(T) xorBool fromConstantExpr(T'))

     rule L:RValue & R:RValue => te(stripHold(L) & stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool isPromoted(utype(L))
               andBool utype(L) ==Type utype(R)
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
     rule L:RValue ^ R:RValue => te(stripHold(L) ^ stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool isPromoted(utype(L))
               andBool utype(L) ==Type utype(R)
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))
     rule L:RValue | R:RValue => te(stripHold(L) | stripHold(R), utype(L))
          requires (isHold(L) orBool isHold(R))
               andBool isPromoted(utype(L))
               andBool utype(L) ==Type utype(R)
               andBool notBool (fromConstantExpr(L) xorBool fromConstantExpr(R))

endmodule
