module VeriTypes

import AST;
import String;

data VType
  = tInt()
  | tBool()
  | tChar()
  | tString()
  | tFloat()
  | tUser(str name)           // spaces + user-defined data structures
  | tUnknown()
  ;

str prettyVType(tInt()) = "Int";
str prettyVType(tBool()) = "Bool";
str prettyVType(tChar()) = "Char";
str prettyVType(tString()) = "String";
str prettyVType(tFloat()) = "Float";
str prettyVType(tUser(str n)) = n;
str prettyVType(tUnknown()) = "unknown";

public str typeName(Type t) {
  switch (t) {
    case intType(): return "Int";
    case boolType(): return "Bool";
    case charType(): return "Char";
    case stringType(): return "String";
    case floatType(): return "Float";
    case typeId(name): return name;
  }
}

VType vtype(Type t) {
  switch (t) {
    case intType(): return tInt();
    case boolType(): return tBool();
    case charType(): return tChar();
    case stringType(): return tString();
    case floatType(): return tFloat();
    case typeId(name): return tUser(name);
    default: return tUnknown();
  }
}

