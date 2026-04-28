module TypeCheck

import AST;
import List;
import Map;
import Set;
import String;

import VeriTypes;

data TcResult = tcResult(bool ok, set[str] messages);
data InferRes = inferRes(VType typ, set[str] messages);

public TcResult typeCheck(Program p) {
  set[str] msgs = {};

  set[str] typeDefs = builtinTypeDefs();
  map[str, VType] vars = ();
  map[str, tuple[list[VType] params, VType ret]] ops = ();

  // Spaces define user types (and parents must exist)
  for (elem <- p.moduleDef.elements) {
    if (spaceDeclElem(spaceDecl(name)) := elem) {
      typeDefs += {name};
    }
    if (spaceDeclElem(spaceDeclExtends(name, parent)) := elem) {
      typeDefs += {name};
      if (!(parent in typeDefs)) {
        msgs += {"Tipo o espacio padre no definido: " + parent};
      }
    }
  }

  // defdata defines user types and references an element type
  for (elem <- p.moduleDef.elements) {
    if (dataDeclElem(dataDecl(name, elemType, _)) := elem) {
      VType et = vtype(elemType);
      if (!typeExists(et, typeDefs)) {
        msgs += {"En defdata " + name + " el tipo de elementos no esta definido: " + prettyVType(et)};
      }
      typeDefs += {name};
    }
  }

  // Variables
  for (elem <- p.moduleDef.elements) {
    if (varDeclElem(varDecl(defs)) := elem) {
      for (varDef(vn, vt) <- defs) {
        VType t = vtype(vt);
        if (!typeExists(t, typeDefs)) {
          msgs += {"Variable " + vn + " usa un tipo no definido: " + prettyVType(t)};
        }
        vars[vn] = t;
      }
    }
  }

  // Operators: types must exist, store signature
  for (elem <- p.moduleDef.elements) {
    if (operatorDeclElem(operatorDecl(on, tys, _)) := elem) {
      list[VType] vts = [vtype(t) | t <- tys];
      for (t <- vts) {
        if (!typeExists(t, typeDefs)) {
          msgs += {"Operador " + on + " usa un tipo no definido: " + prettyVType(t)};
        }
      }
      if (size(vts) >= 1) {
        list[VType] ps = [];
        if (size(vts) > 1) {
          int i = 0;
          while (i < size(vts) - 1) {
            ps += [vts[i]];
            i += 1;
          }
        }
        ops[on] = <ps, vts[size(vts) - 1]>;
      }
    }
  }

  // RULE (6): elements used in defdata must exist in defvar and match elem type
  for (elem <- p.moduleDef.elements) {
    if (dataDeclElem(dataDecl(name, elemType, elems)) := elem) {
      VType et = vtype(elemType);
      for (e <- elems) {
        if (!(e in vars)) {
          msgs += {"En defdata " + name + " el elemento no existe (no esta en defvar): " + e};
        }
        else if (vars[e] != et) {
          msgs += {"En defdata " + name + " el elemento " + e + " tiene tipo " + prettyVType(vars[e]) + " pero se esperaba " + prettyVType(et)};
        }
      }
    }
  }

  // Expressions (5): ensure types are consistent and annotations match
  for (elem <- p.moduleDef.elements) {
    if (expressionDeclElem(expressionDecl(expr, _)) := elem) {
      InferRes ir = inferExpr(expr, vars, ops, typeDefs);
      msgs += ir.messages;
      if (ir.typ == tUnknown()) {
        msgs += {"No se pudo inferir el tipo de una expresion"};
      }
    }
  }

  bool ok = isEmpty(msgs);
  return tcResult(ok, msgs);
}

InferRes inferExpr(Expression e,
                   map[str, VType] vars,
                   map[str, tuple[list[VType] params, VType ret]] ops,
                   set[str] typeDefs) {
  set[str] msgs = {};

  if (intLit(_) := e) return inferRes(tInt(), {});
  if (floatLit(_) := e) return inferRes(tFloat(), {});
  if (boolLit(_) := e) return inferRes(tBool(), {});
  if (charLit(_) := e) return inferRes(tChar(), {});
  if (stringLit(_) := e) return inferRes(tString(), {});

  if (idExpr(n) := e) {
    if (n in vars) return inferRes(vars[n], {});
    return inferRes(tUnknown(), {"Identificador no declarado: " + n});
  }

  if (annotated(expr, typ) := e) {
    VType ann = vtype(typ);
    if (!typeExists(ann, typeDefs)) {
      msgs += {"Anotacion de tipo no definida: " + prettyVType(ann)};
    }
    InferRes inner = inferExpr(expr, vars, ops, typeDefs);
    msgs += inner.messages;
    if (inner.typ != tUnknown() && ann != tUnknown() && inner.typ != ann) {
      msgs += {"Anotacion incompatible: esperaba " + prettyVType(ann) + " pero obtuvo " + prettyVType(inner.typ)};
    }
    return inferRes(ann == tUnknown() ? inner.typ : ann, msgs);
  }

  if (negExpr(x) := e) {
    // Treat `neg` as operator `neg` if declared.
    if ("neg" in ops) {
      sig = ops["neg"];
      list[VType] ps = sig.params;
      VType rt = sig.ret;
      InferRes ix = inferExpr(x, vars, ops, typeDefs);
      msgs += ix.messages;
      if (size(ps) == 1 && ix.typ != tUnknown() && ix.typ != ps[0]) msgs += {"neg: tipo incorrecto"};
      return inferRes(rt, msgs);
    }
    InferRes ix = inferExpr(x, vars, ops, typeDefs);
    msgs += ix.messages;
    return inferRes(tUnknown(), msgs);
  }

  // Logical connectives: use operator declarations when available.
  if (andExpr(l, r) := e) return op2("and", l, r, vars, ops, typeDefs);
  if (orExpr(l, r) := e) return op2("or", l, r, vars, ops, typeDefs);
  if (implication(l, r) := e) return op2("implies", l, r, vars, ops, typeDefs);
  if (equivalence(l, r) := e) return sameType2("equiv", l, r, vars, ops, typeDefs);

  if (addExpr(l, r) := e) return binNum(l, r, vars, ops, typeDefs, false);
  if (subExpr(l, r) := e) return binNum(l, r, vars, ops, typeDefs, false);
  if (mulExpr(l, r) := e) return binNum(l, r, vars, ops, typeDefs, false);
  if (divExpr(l, r) := e) return binNum(l, r, vars, ops, typeDefs, false);
  if (modExpr(l, r) := e) return binNum(l, r, vars, ops, typeDefs, true);
  if (powExpr(l, r) := e) return binNum(l, r, vars, ops, typeDefs, false);

  if (ltExpr(l, r) := e) return binCmp(l, r, vars, ops, typeDefs);
  if (gtExpr(l, r) := e) return binCmp(l, r, vars, ops, typeDefs);
  if (lteExpr(l, r) := e) return binCmp(l, r, vars, ops, typeDefs);
  if (gteExpr(l, r) := e) return binCmp(l, r, vars, ops, typeDefs);

  if (eqExpr(l, r) := e) return eqCheck(l, r, vars, ops, typeDefs);
  if (neqExpr(l, r) := e) return eqCheck(l, r, vars, ops, typeDefs);

  if (quantifiedForall(v, d, b) := e) {
    VType dom = tUser(d);
    if (!(d in typeDefs)) msgs += {"Dominio no definido: " + d};
    map[str, VType] vars2 = vars + (v: dom);
    InferRes ib = inferExpr(b, vars2, ops, typeDefs);
    msgs += ib.messages;
    // Quantifiers yield a proposition-like result (use `proposition` if it exists, else Bool).
    if ("proposition" in typeDefs) return inferRes(tUser("proposition"), msgs);
    return inferRes(tBool(), msgs);
  }

  if (quantifiedExists(v, d, b) := e) {
    VType dom = tUser(d);
    if (!(d in typeDefs)) msgs += {"Dominio no definido: " + d};
    map[str, VType] vars2 = vars + (v: dom);
    InferRes ib = inferExpr(b, vars2, ops, typeDefs);
    msgs += ib.messages;
    if ("proposition" in typeDefs) return inferRes(tUser("proposition"), msgs);
    return inferRes(tBool(), msgs);
  }

  if (application(op, args) := e) {
    if (!(op in ops)) return inferRes(tUnknown(), {"Operador no declarado: " + op});
    sig = ops[op];
    list[VType] params = sig.params;
    VType ret = sig.ret;
    if (size(params) != size(args)) msgs += {"Aridad incorrecta en " + op};
    int n = size(params);
    if (size(args) < n) n = size(args);
    int i = 0;
    while (i < n) {
      InferRes a = inferExpr(args[i], vars, ops, typeDefs);
      msgs += a.messages;
      if (a.typ != tUnknown() && a.typ != params[i]) msgs += {"Argumento con tipo incorrecto en " + op};
      i += 1;
    }
    return inferRes(ret, msgs);
  }

  return inferRes(tUnknown(), msgs);
}

InferRes op2(str op, Expression l, Expression r,
             map[str, VType] vars,
             map[str, tuple[list[VType] params, VType ret]] ops,
             set[str] typeDefs) {
  set[str] msgs = {};
  if (!(op in ops)) return inferRes(tUnknown(), {"Operador no declarado: " + op});
  sig = ops[op];
  list[VType] ps = sig.params;
  VType rt = sig.ret;
  InferRes il = inferExpr(l, vars, ops, typeDefs);
  InferRes ir = inferExpr(r, vars, ops, typeDefs);
  msgs += il.messages + ir.messages;
  if (size(ps) == 2) {
    if (il.typ != tUnknown() && il.typ != ps[0]) msgs += {op + ": tipo incorrecto izq"};
    if (ir.typ != tUnknown() && ir.typ != ps[1]) msgs += {op + ": tipo incorrecto der"};
  }
  return inferRes(rt, msgs);
}

InferRes sameType2(str opname, Expression l, Expression r,
                   map[str, VType] vars,
                   map[str, tuple[list[VType] params, VType ret]] ops,
                   set[str] typeDefs) {
  set[str] msgs = {};
  InferRes il = inferExpr(l, vars, ops, typeDefs);
  InferRes ir = inferExpr(r, vars, ops, typeDefs);
  msgs += il.messages + ir.messages;
  if (il.typ != tUnknown() && ir.typ != tUnknown() && il.typ != ir.typ) msgs += {opname + ": tipos distintos"};
  // return same type (or unknown)
  if (il.typ != tUnknown()) return inferRes(il.typ, msgs);
  return inferRes(ir.typ, msgs);
}

InferRes binNum(Expression l, Expression r,
                map[str, VType] vars,
                map[str, tuple[list[VType] params, VType ret]] ops,
                set[str] typeDefs,
                bool onlyInt) {
  set[str] msgs = {};
  InferRes il = inferExpr(l, vars, ops, typeDefs);
  InferRes ir = inferExpr(r, vars, ops, typeDefs);
  msgs += il.messages + ir.messages;

  bool lNum = (il.typ == tInt()) || (il.typ == tFloat()) || (il.typ == tUser("arithmetic"));
  bool rNum = (ir.typ == tInt()) || (ir.typ == tFloat()) || (ir.typ == tUser("arithmetic"));
  if (!lNum) msgs += {"Operacion numerica: lado izquierdo no es numero (" + prettyVType(il.typ) + ")"};
  if (!rNum) msgs += {"Operacion numerica: lado derecho no es numero (" + prettyVType(ir.typ) + ")"};

  if (onlyInt) {
    bool wrong = false;
    if (il.typ != tInt()) wrong = true;
    if (ir.typ != tInt()) wrong = true;
    if (wrong) msgs += {"Operacion numerica: solo definida para Int"};
  }

  // If we are in the user-defined arithmetic space, keep results in that space.
  if (il.typ == tUser("arithmetic") || ir.typ == tUser("arithmetic")) {
    return inferRes(tUser("arithmetic"), msgs);
  }

  if (il.typ == tFloat() || ir.typ == tFloat()) return inferRes(tFloat(), msgs);
  if (il.typ == tInt() && ir.typ == tInt()) return inferRes(tInt(), msgs);
  return inferRes(tUnknown(), msgs);
}

InferRes binCmp(Expression l, Expression r,
                map[str, VType] vars,
                map[str, tuple[list[VType] params, VType ret]] ops,
                set[str] typeDefs) {
  InferRes ir = binNum(l, r, vars, ops, typeDefs, false);
  return inferRes(tBool(), ir.messages);
}

InferRes eqCheck(Expression l, Expression r,
                 map[str, VType] vars,
                 map[str, tuple[list[VType] params, VType ret]] ops,
                 set[str] typeDefs) {
  set[str] msgs = {};
  InferRes il = inferExpr(l, vars, ops, typeDefs);
  InferRes ir = inferExpr(r, vars, ops, typeDefs);
  msgs += il.messages + ir.messages;
  if (il.typ != tUnknown() && ir.typ != tUnknown() && il.typ != ir.typ) msgs += {"Comparacion entre tipos distintos"};
  return inferRes(tBool(), msgs);
}

set[str] builtinTypeDefs() = {"Int","Bool","Char","String","Float"};

bool typeExists(VType t, set[str] typeDefs) {
  switch (t) {
    case tUser(n): return n in typeDefs;
    case tInt(): return true;
    case tBool(): return true;
    case tChar(): return true;
    case tString(): return true;
    case tFloat(): return true;
    default: return false;
  }
}

public bool _typecheckModuleLoads() = true;
