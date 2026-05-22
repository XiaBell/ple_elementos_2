module VeriTypes

import AST;
import String;

data VType
  = tInt()
  | tBool()
  | tChar()
  | tString()
  | tFloat()
  | tUser(str name)
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
  if (intType() := t) return "Int";
  if (boolType() := t) return "Bool";
  if (charType() := t) return "Char";
  if (stringType() := t) return "String";
  if (floatType() := t) return "Float";
  if (typeId(str name) := t) return name;
  return "?";
}

VType vtype(Type t) {
  if (intType() := t) return tInt();
  if (boolType() := t) return tBool();
  if (charType() := t) return tChar();
  if (stringType() := t) return tString();
  if (floatType() := t) return tFloat();
  if (typeId(str name) := t) return tUser(name);
  return tUnknown();
}
