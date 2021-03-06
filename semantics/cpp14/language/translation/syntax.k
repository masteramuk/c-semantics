module CPP-ABSTRACT-SYNTAX
     imports COMPAT-SYNTAX

     syntax Decl ::= TranslationUnit(List)
                   | LinkageSpec(String, List)
                   | FunctionDefinition(Namespace, CId, AType, Stmt)
                   | Declarator(Namespace, CId, AType)

     syntax Type // defined in CPP-DYNAMIC-SYNTAX

     syntax AType ::= Type
                    | FunctionPrototype(AType, List, List, Expr, Bool)
                    | BuiltinType(AType)
                    | PointerType(AType)

     syntax AType ::= Void() | Char() | Bool() | UChar() | UShort() 
                    | UInt() | ULong() | ULongLong() | SChar() | Short()
                    | Int() | Long() | LongLong() | Float() | Double()
                    | LongDouble()

     syntax AType ::= Qualifier(Qualifier, AType)

     syntax Namespace ::= NoNamespace()

     syntax Stmt ::= CompoundStmt(List)
                   | LabelStmt(CId, List)
                   | GotoStmt(CId)
                   | Expr //expression statement, handled later

     syntax Expr ::= CallExpr(Expr, List)
                   | DeclRef(Namespace, CId)
                   | StringLiteral(String)

endmodule
