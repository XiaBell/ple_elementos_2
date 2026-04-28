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

VType vtype(Type t) {
  switch (t) {
    case typeId(name): {
      switch (name) {
        case "Int": return tInt();
        case "Bool": return tBool();
        case "Char": return tChar();
        case "String": return tString();
        case "Float": return tFloat();
        default: return tUser(name);
      }
    }
  }
}

