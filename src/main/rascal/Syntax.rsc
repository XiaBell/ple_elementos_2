module Syntax

layout Layout = WhitespaceAndComment* !>> [\ \t\n\r#];
lexical WhitespaceAndComment 
    = [\ \t\n\r] 
    | @category="Comment" "#" ![\n]* $;

// === 5.1 Program Structure ===

start syntax Program 
    = program: Module moduleDef;

syntax Module 
    = \module: "defmodule" Identifier name 
               UsingDecl* usings 
               ModuleElement* elements 
               "end";

syntax UsingDecl 
    = usingDecl: "using" Identifier name;

syntax ModuleElement 
    = spaceDeclElem:      SpaceDecl spaceDecl
    | operatorDeclElem:   OperatorDecl operatorDecl
    | varDeclElem:        VarDecl varDecl
    | dataDeclElem:       DataDecl dataDecl
    | ruleDeclElem:       RuleDecl ruleDecl
    | expressionDeclElem: ExpressionDecl expressionDecl;

// === 5.2 Space Declaration ===

syntax SpaceDecl 
    = spaceDeclExtends: "defspace" Identifier name "\<" Identifier parent "end"
    | spaceDecl:        "defspace" Identifier name "end";

// === 5.3 Operator Declaration ===

syntax OperatorDecl 
    = operatorDecl: "defoperator" OpName name ":" {Type "-\>"}+ types 
                    AttributeBlock? attrs "end";

syntax Type 
    = typeId: Identifier name;

// === 5.4 Attributes ===

syntax AttributeBlock 
    = attributeBlock: "[" Attribute+ attrs "]";

syntax Attribute 
    = attrKeyValue: Identifier key ":" Identifier val
    | attrSimple:   Identifier name;

// === 5.5 Variable Declaration ===

syntax VarDecl 
    = varDecl: "defvar" {VarDef ","}+ defs "end";

syntax VarDef 
    = varDef: Identifier name ":" Type typ;

// === 5.x Data structure declaration ===

syntax DataDecl
    = dataDecl: "defdata" Identifier name ":" Type elemType "=" "{" {Identifier ","}* elems "}" "end";

// === 5.6 Rule Declaration ===

syntax RuleDecl 
    = ruleDecl: "defrule" GramOperatorApplication lhs "-\>" GramOperatorApplication rhs "end";

// Name distinct from AST data OperatorApplication (Parser transitively imports Syntax into Generator).
syntax GramOperatorApplication 
    = operatorApplication: "(" OpName op Expression+ args ")";

// === 5.7 Expression Declaration ===

syntax ExpressionDecl 
    = expressionDecl: "defexpression" Expression expr AttributeBlock? attrs "end";

// === 5.7 Expressions (full precedence) ===

syntax Expression 
    = right  implication:  Expression "=\>"  Expression
    > right  equivalence:  Expression "\u2261" Expression
    > right  orExpr:       Expression "or"   Expression
    > right  andExpr:      Expression "and"  Expression
    > non-assoc (
          eqExpr:  Expression "="    Expression
        | ltExpr:  Expression "\<"   Expression
        | gtExpr:  Expression "\>"   Expression
        | lteExpr: Expression "\<="  Expression
        | gteExpr: Expression "\>="  Expression
        | neqExpr: Expression "\<\>" Expression
      )
    > left (
          addExpr: Expression "+" Expression
        | subExpr: Expression "-" Expression
      )
    > right powExpr: Expression "**" Expression
    > left (
          mulExpr: Expression "*"  Expression
        | divExpr: Expression "/"  Expression
        | modExpr: Expression "%"  Expression
      )
    > negExpr: "neg" Expression
    > right annotated: Expression ":" Type
    > idExpr:           Identifier name
    | application:      "(" Identifier op Expression+ args ")"
    | quantifiedForall: "forall" Identifier var "in" Identifier domain "." Expression body
    | quantifiedExists: "exists" Identifier var "in" Identifier domain "." Expression body
    | intLit:           IntLiteral intVal
    | floatLit:         FloatLiteral floatRaw
    | charLit:          CharLiteral charVal
    | boolLit:          BoolLiteral boolRaw
    | stringLit:        StringLiteral stringVal
    | bracket           "(" Expression ")"
    ;

// === 5.10 Tokens & Literals ===

lexical Identifier 
    = ([a-zA-Z][a-zA-Z0-9]*("-"[a-zA-Z0-9][a-zA-Z0-9]*)* !>> [a-zA-Z0-9]) \ AllKeywords;

lexical OpName 
    = ([a-zA-Z][a-zA-Z0-9]*("-"[a-zA-Z0-9][a-zA-Z0-9]*)* !>> [a-zA-Z0-9]) \ StructKeywords;

lexical IntLiteral 
    = @category="Constant" [0-9]+ !>> [0-9.];

lexical FloatLiteral 
    = [0-9]+ "." [0-9]+ [eE] [+\-]? [0-9]+ !>> [0-9]
    | [0-9]+ "." [0-9]+ !>> [0-9.eE];

lexical CharLiteral 
    = @category="StringLiteral" "\'" ![\'\n] "\'";

lexical BoolLiteral
    = @category="Keyword" "true" !>> [a-zA-Z0-9]
    | @category="Keyword" "false" !>> [a-zA-Z0-9];

lexical StringLiteral
    = @category="StringLiteral" "\"" ![\"\n]* "\"";

keyword AllKeywords 
    = "defmodule" | "using" | "defspace" | "defrule" | "end"
    | "defoperator" | "defexpression" | "defvar" | "defdata" | "defer"
    | "forall" | "exists" | "in"
    | "and" | "or" | "neg"
    | "true" | "false";

keyword StructKeywords 
    = "defmodule" | "using" | "defspace" | "defrule" | "end"
    | "defoperator" | "defexpression" | "defvar" | "defdata" | "defer"
    | "forall" | "exists" | "in";
