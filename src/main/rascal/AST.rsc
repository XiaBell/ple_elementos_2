module AST

data Program 
    = program(Module moduleDef);

data Module 
    = \module(str name, list[UsingDecl] usings, list[ModuleElement] elements);

data UsingDecl 
    = usingDecl(str name);

data ModuleElement 
    = spaceDeclElem(SpaceDecl decl)
    | operatorDeclElem(OperatorDecl decl)
    | varDeclElem(VarDecl decl)
    | ruleDeclElem(RuleDecl decl)
    | expressionDeclElem(ExpressionDecl decl);

data SpaceDecl 
    = spaceDeclExtends(str name, str parent)
    | spaceDecl(str name);

data OperatorDecl 
    = operatorDecl(str name, list[Type] types, list[AttributeBlock] attrs);

data Type 
    = typeId(str name);

data AttributeBlock 
    = attributeBlock(list[Attribute] attrs);

data Attribute 
    = attrKeyValue(str key, str val)
    | attrSimple(str name);

data VarDecl 
    = varDecl(list[VarDef] defs);

data VarDef 
    = varDef(str name, Type typ);

data RuleDecl 
    = ruleDecl(OperatorApplication lhs, OperatorApplication rhs);

data OperatorApplication 
    = operatorApplication(str op, list[Expression] args);

data ExpressionDecl 
    = expressionDecl(Expression expr, list[AttributeBlock] attrs);

data Expression 
    = implication(Expression lhs, Expression rhs)
    | equivalence(Expression lhs, Expression rhs)
    | orExpr(Expression lhs, Expression rhs)
    | andExpr(Expression lhs, Expression rhs)
    | eqExpr(Expression lhs, Expression rhs)
    | ltExpr(Expression lhs, Expression rhs)
    | gtExpr(Expression lhs, Expression rhs)
    | lteExpr(Expression lhs, Expression rhs)
    | gteExpr(Expression lhs, Expression rhs)
    | neqExpr(Expression lhs, Expression rhs)
    | addExpr(Expression lhs, Expression rhs)
    | subExpr(Expression lhs, Expression rhs)
    | powExpr(Expression lhs, Expression rhs)
    | mulExpr(Expression lhs, Expression rhs)
    | divExpr(Expression lhs, Expression rhs)
    | modExpr(Expression lhs, Expression rhs)
    | negExpr(Expression expr)
    | idExpr(str name)
    | application(str op, list[Expression] args)
    | quantifiedForall(str var, str domain, Expression body)
    | quantifiedExists(str var, str domain, Expression body)
    | intLit(int val)
    | floatLit(str raw)
    | charLit(str val);
