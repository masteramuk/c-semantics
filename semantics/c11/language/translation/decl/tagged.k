module C-DECL-TAGGED-SYNTAX
     imports C-ABSTRACT-SYNTAX
     // Not defined, just used.
     syntax KItem ::= addGlobalTag(CId, FieldInfo)
     syntax KItem ::= addLocalTag(CId, FieldInfo)

     syntax FieldInfo ::= makeStructFieldInfo(List) [function]
     syntax FieldInfo ::= makeUnionFieldInfo(List) [function]
endmodule

module C-DECL-TAGGED
     imports C-DECL-TAGGED-SYNTAX

     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     context StructDef(_, HOLE:KItem => seqstrict(HOLE))
     context UnionDef(_, HOLE:KItem => seqstrict(HOLE))

     // TODO(chathhorn): handle global/local differently.
     // note that struct defs might appear buried in a type.
     rule StructDef(X:CId, krlist(L:List))
          => addTag(X, makeStructFieldInfo(L))
          requires hasNamedField(L)
          [structural]
     rule (.K => UNDEF("CDT1", "Structs must contain a named member.", "6.7.2.1:8, J.2:1 item 61") )
          ~> StructDef(_, krlist(L:List))
          requires notBool hasNamedField(L)
          [structural]
     rule UnionDef(X:CId, krlist(L:List))
          => addTag(X, makeUnionFieldInfo(L))
          requires hasNamedField(L)
          [structural]
     rule (.K => UNDEF("CDT2", "Unions must contain a named member.", "6.7.2.1, J.2:1 item 61") )
          ~> UnionDef(_, krlist(L:List))
          requires notBool hasNamedField(L)
          [structural]

     syntax Bool ::= hasNamedField(List) [function]
     rule hasNamedField(ListItem(typedDeclaration(_, F:CId)) _) => true
          requires F =/=K #NoName
     rule hasNamedField((ListItem(typedDeclaration(_, #NoName)) => .List) _)
     rule hasNamedField(.List) => false

     rule makeStructFieldInfo(L:List)
          => makeStructFieldInfo'(
               incompleteToFlexibleArrayMember(L),
               0, .Map, .Map,
               incompleteToFlexibleArrayMember(L))

     syntax FieldInfo ::= "makeStructFieldInfo'" "(" List "," Int "," Map ","  Map "," List ")"
                         [function]
     syntax Int ::= structPadding(Int, Type) [function]
                  | structPadding(Int, Int) [function, klabel(structPadding2)]

     rule makeStructFieldInfo'(
               ListItem(typedDeclaration(T:Type, Field:CId)) L:List
               , V:Int
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeStructFieldInfo'(L, V +Int bitSizeofType(T) +Int structPadding(V, T),
               Types[Field <- T], Offsets[Field <- V +Int structPadding(V, T)], L')
     rule makeStructFieldInfo'(.List, V:Int, Types:Map, Offsets:Map, L:List)
          => fieldInfo(L, (V +Int structPadding(V, maxByteAlignofList(L))), Types, Offsets, computePaddingOffsets(L, (V +Int structPadding(V, maxByteAlignofList(L))), Types, Offsets, 0))

     rule structPadding(Offset::Int, t(_, _, bitfieldType(T::BitfieldFieldType, N::Int))) => 0
          requires (Offset +Int bitSizeofType(type(bitfieldType(T, N))) -Int 1) /Int cfg:bitsPerByte -Int Offset /Int cfg:bitsPerByte
                    <Int byteAlignofType(type(T))
               andBool N >Int 0
     // if we can add the new bits without the new field crossing an alignment boundary, use no padding
     rule structPadding(Offset:Int, T::Type) => structPadding(Offset, byteAlignofType(T)) [owise]
     // otherwise, or if not a bit field, use the alignment of the field as padding
     rule structPadding(Offset:Int, Alignment:Int)
          => (0 -Int Offset) modInt (Alignment *Int cfg:bitsPerByte)

     // FIXME: chould check for some struct contraints here.
     syntax List ::= incompleteToFlexibleArrayMember(List) [function]
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(T:Type, X:CId))
          L:List)
          => ListItem(typedDeclaration(T, X)) incompleteToFlexibleArrayMember(L)
          requires isCompleteType(T)
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(t(Qs::Quals, Mods::Set, incompleteArrayType(T::Type)), X:CId)))
          => ListItem(typedDeclaration(t(Qs, Mods, flexibleArrayType(T)), X))
     rule incompleteToFlexibleArrayMember(.List) => .List

     rule makeUnionFieldInfo(L:List) => makeUnionFieldInfo'(L, .Map, .Map, L)

     syntax FieldInfo ::= "makeUnionFieldInfo'" "(" List "," Map ","  Map "," List ")"
                         [function]
     rule makeUnionFieldInfo'(
               ListItem(typedDeclaration(T:Type, Field:CId)) L:List
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeUnionFieldInfo'(L,
               Types[Field <- T], Offsets[Field <- 0], L')
     rule makeUnionFieldInfo'(.List, Types:Map, Offsets:Map, L:List)
          => fieldInfo(L, maxByteSizeofList(L) *Int cfg:bitsPerByte, Types, Offsets, computePaddingOffsets(L, maxByteSizeofList(L) *Int cfg:bitsPerByte, Types, Offsets, 0))

     syntax Set ::= computePaddingOffsets(List, Int, Map, Map, Int) [function]
     rule computePaddingOffsets(L::List, Len::Int, Types::Map, Offsets::Map, Offset::Int)
          => SetItem(Offset) computePaddingOffsets(L, Len, Types, Offsets, Offset +Int cfg:bitsPerByte)
          requires notBool isNonPaddingOffset(Offset, L, Types, Offsets) andBool Offset <Int Len
     rule computePaddingOffsets(L::List, Len::Int, Types::Map, Offsets::Map, (Offset::Int => Offset +Int cfg:bitsPerByte))
          requires isNonPaddingOffset(Offset, L, Types, Offsets) andBool Offset <Int Len
     rule computePaddingOffsets(_, Len::Int, _, _, Offset::Int) => .Set
          requires Offset >=Int Len

     syntax Bool ::= isNonPaddingOffset(Int, List, Map, Map) [function]
     rule isNonPaddingOffset(Offset:Int, ListItem(typedDeclaration(_, F:CId)) Decls:List, Types:Map, Offsets:Map)
          => (Offsets[F]<:K:>Int <=Int Offset andBool Offset <Int Offsets[F]<:K:>Int +Int
               bitSizeofType(Types[F]<:K:>Type))
          orBool isNonPaddingOffset(Offset, Decls, Types, Offsets)
     rule isNonPaddingOffset(_, .List, _, _) => false

     syntax KItem ::= addTag(CId, FieldInfo)
     rule <k> addTag(S:CId, fieldInfo(Fs:List, NBits:Int, Ts:Map, Offs:Map, PaddingOffs:Set))
               // Elide function parameter names in struct types.
               => addGlobalTag(S, fieldInfo(elideList(Fs), NBits, elideMap(Ts), Offs, PaddingOffs))
          ...</k>
          <curr-scope> fileScope </curr-scope>
          [structural]
     rule <k> addTag(S:CId, fieldInfo(Fs:List, NBits:Int, Ts:Map, Offs:Map, PaddingOffs:Set))
               => addLocalTag(S, fieldInfo(elideList(Fs), NBits, elideMap(Ts), Offs, PaddingOffs))
          ...</k>
          <curr-scope> Scope:Scope </curr-scope>
          requires isFileScope(Scope) =/=K true
          [structural]

     rule <k> addLocalTag(_, _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <structs> S:Map => S[Tu <- .Map] </structs>
          requires notBool (Tu in_keys(S))

     rule <k> addLocalTag(X:CId, Info:FieldInfo) => .K ...</k>
          <structs>... Tu |-> (Structs:Map => Structs[tag(X, Tu, BlockNum) <- Info]) ...</structs>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          requires notBool (tag(X, Tu, global) in_keys(Structs))
               andBool notBool (tag(X, Tu, BlockNum) in_keys(Structs))
          [structural]
     rule <k> (.K => CV("TDG15", "Redefinition of a struct, union, or enum: "
               +String idToString(X), "6.7.2.3:1"))
               ~> addLocalTag(X:CId, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <structs>... Tu |-> Structs:Map ...</structs>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          requires (tag(X, Tu, global) in_keys(Structs))
               orBool (tag(X, Tu, BlockNum) in_keys(Structs))
          [structural]
endmodule

