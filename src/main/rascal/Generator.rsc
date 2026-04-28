module Generator

import IO;
import List;
import String;
import AST;
import Parser;
import Implode;
import util::SystemAPI;
import TypeCheck;
import analysis::typepal::TypePal;

// ============================================================
// Entry points
// ============================================================

loc inputLoc(str path) {
    str n = replaceAll(path, "\\", "/");
    if (size(n) > 0 && startsWith(n, "/")) {
        return |file:///| + substring(n, 1);
    }
    if (/^[a-zA-Z]:\/.*/ := n) {
        return |file:///| + n;
    }
    return |file:///| + getSystemProperty("user.dir") + "/" + n;
}

void main(list[str] args) {
    loc root = |file:///| + getSystemProperty("user.dir") + "/";
    loc input = size(args) > 0 ? inputLoc(args[0]) : root + "instance/example.vl";
    cst = parseProgram(input);
    // TypePal is installed (dependency + import). Concrete checks run on the AST below.
    Program p = implodeProgram(cst.top);
    TcResult r = typeCheck(p);
    if (!r.ok) {
        for (m <- r.messages) println(m);
        throw "Type checking failed";
    }
    result = generateFromAST(p);
    println(result);
    writeFile(root + "instance/output/verilang-output.txt", result);
}

str generate(cast) {
    ast = implodeProgram(cast.top);
    return generateFromAST(ast);
}

str generateFromAST(Program prog) {
    rules = collectRules(prog.moduleDef.elements);
    return generateProgram(prog, rules);
}

// ============================================================
// Collect rewrite rules
// ============================================================

alias Rule = tuple[OperatorApplication lhs, OperatorApplication rhs];

list[Rule] collectRules(list[ModuleElement] elems) {
    list[Rule] result = [];
    for (elem <- elems) {
        if (ruleDeclElem(ruleDecl(lhs, rhs)) := elem) {
            result += [<lhs, rhs>];
        }
    }
    return result;
}

// ============================================================
// Pretty-print the whole program
// ============================================================

str generateProgram(Program prog, list[Rule] rules) {
    m = prog.moduleDef;
    str out = "=== VeriLang Module: <m.name> ===\n\n";
    out += generateUsings(m.usings);
    out += generateElements(m.elements, rules);
    out += "=== End Module ===\n";
    return out;
}

str generateUsings(list[UsingDecl] usings) {
    str out = "";
    for (u <- usings) {
        out += "Using: <u.name>\n";
    }
    return out;
}

str generateElements(list[ModuleElement] elems, list[Rule] rules) {
    str out = "";
    for (elem <- elems) {
        out += generateElement(elem, rules);
    }
    return out;
}

str generateElement(ModuleElement elem, list[Rule] rules) {
    switch (elem) {
        case spaceDeclElem(sd):      return generateSpace(sd);
        case operatorDeclElem(od):   return generateOperator(od);
        case varDeclElem(vd):        return generateVar(vd);
        case ruleDeclElem(rd):       return generateRule(rd);
        case expressionDeclElem(ed): return generateExpression(ed, rules);
    }
    return "";
}

// ============================================================
// Generate declarations
// ============================================================

str generateSpace(SpaceDecl decl) {
    switch (decl) {
        case spaceDeclExtends(name, parent):
            return "Space: <name> extends <parent>\n";
        case spaceDecl(name):
            return "Space: <name>\n";
    }
    return "";
}

str generateOperator(OperatorDecl decl) {
    str sig = intercalate(" -\> ", [ t.name | t <- decl.types ]);
    str out = "Operator: <decl.name> : <sig>";
    out += generateAttrBlocks(decl.attrs);
    return out + "\n";
}

str generateVar(VarDecl decl) {
    str defs = intercalate(", ", [ "<d.name> : <d.typ.name>" | d <- decl.defs ]);
    return "Variables: <defs>\n";
}

str generateRule(RuleDecl decl) {
    return "Rule: <ppOpApp(decl.lhs)> -\> <ppOpApp(decl.rhs)>\n";
}

str generateExpression(ExpressionDecl decl, list[Rule] rules) {
    Expression original = decl.expr;
    Expression rewritten = applyAllRules(original, rules);
    Expression evaluated = evalExpr(rewritten);

    str out = "Expression:\n";
    out += "  original:  <ppExpr(original)>\n";

    if (rewritten != original) {
        out += "  rewritten: <ppExpr(rewritten)>\n";
    }
    if (evaluated != rewritten) {
        out += "  evaluated: <ppExpr(evaluated)>\n";
    }

    out += "  result:    <ppExpr(evaluated)>\n";
    out += generateAttrBlocks(decl.attrs);
    return out;
}

str generateAttrBlocks(list[AttributeBlock] blocks) {
    str out = "";
    for (block <- blocks) {
        list[str] items = [];
        for (a <- block.attrs) {
            switch (a) {
                case attrKeyValue(k, v): items += ["<k>: <v>"];
                case attrSimple(n):      items += [n];
            }
        }
        out += " [<intercalate(", ", items)>]";
    }
    return out;
}

// ============================================================
// Pretty-print expressions
// ============================================================

str ppOpApp(OperatorApplication oa) =
    "(<oa.op> <intercalate(" ", [ ppExprArg(e) | e <- oa.args ])>)";

str ppExpr(implication(l, r))  = "<ppExprArg(l)> =\> <ppExprArg(r)>";
str ppExpr(equivalence(l, r))  = "<ppExprArg(l)> \u2261 <ppExprArg(r)>";
str ppExpr(orExpr(l, r))       = "<ppExprArg(l)> or <ppExprArg(r)>";
str ppExpr(andExpr(l, r))      = "<ppExprArg(l)> and <ppExprArg(r)>";
str ppExpr(eqExpr(l, r))       = "<ppExprArg(l)> = <ppExprArg(r)>";
str ppExpr(ltExpr(l, r))       = "<ppExprArg(l)> \< <ppExprArg(r)>";
str ppExpr(gtExpr(l, r))       = "<ppExprArg(l)> \> <ppExprArg(r)>";
str ppExpr(lteExpr(l, r))      = "<ppExprArg(l)> \<= <ppExprArg(r)>";
str ppExpr(gteExpr(l, r))      = "<ppExprArg(l)> \>= <ppExprArg(r)>";
str ppExpr(neqExpr(l, r))      = "<ppExprArg(l)> \<\> <ppExprArg(r)>";
str ppExpr(addExpr(l, r))      = "<ppExprArg(l)> + <ppExprArg(r)>";
str ppExpr(subExpr(l, r))      = "<ppExprArg(l)> - <ppExprArg(r)>";
str ppExpr(mulExpr(l, r))      = "<ppExprArg(l)> * <ppExprArg(r)>";
str ppExpr(divExpr(l, r))      = "<ppExprArg(l)> / <ppExprArg(r)>";
str ppExpr(modExpr(l, r))      = "<ppExprArg(l)> % <ppExprArg(r)>";
str ppExpr(powExpr(l, r))      = "<ppExprArg(l)> ** <ppExprArg(r)>";
str ppExpr(negExpr(e))         = "neg <ppExprArg(e)>";
str ppExpr(idExpr(n))          = n;
str ppExpr(application(op, args))         = "(<op> <intercalate(" ", [ ppExprArg(e) | e <- args ])>)";
str ppExpr(quantifiedForall(v, d, body))  = "forall <v> in <d>. <ppExpr(body)>";
str ppExpr(quantifiedExists(v, d, body))  = "exists <v> in <d>. <ppExpr(body)>";
str ppExpr(annotated(e, t))      = "<ppExpr(e)> : <t.name>";
str ppExpr(intLit(n))          = "<n>";
str ppExpr(floatLit(fr))       = fr;
str ppExpr(charLit(cv))        = cv;
str ppExpr(boolLit(br))        = br;
str ppExpr(stringLit(sv))      = sv;

default str ppExpr(Expression e) = "??";

str ppExprArg(e:idExpr(_))          = ppExpr(e);
str ppExprArg(e:intLit(_))          = ppExpr(e);
str ppExprArg(e:floatLit(_))        = ppExpr(e);
str ppExprArg(e:charLit(_))         = ppExpr(e);
str ppExprArg(e:boolLit(_))         = ppExpr(e);
str ppExprArg(e:stringLit(_))       = ppExpr(e);
str ppExprArg(e:application(_, _))  = ppExpr(e);
default str ppExprArg(Expression e) = "(<ppExpr(e)>)";

// ============================================================
// Expression evaluation (integer arithmetic)
// ============================================================

Expression evalExpr(addExpr(l, r)) {
    Expression el = evalExpr(l);
    Expression er = evalExpr(r);
    if (intLit(a) := el, intLit(b) := er) return intLit(a + b);
    return addExpr(el, er);
}

Expression evalExpr(subExpr(l, r)) {
    Expression el = evalExpr(l);
    Expression er = evalExpr(r);
    if (intLit(a) := el, intLit(b) := er) return intLit(a - b);
    return subExpr(el, er);
}

Expression evalExpr(mulExpr(l, r)) {
    Expression el = evalExpr(l);
    Expression er = evalExpr(r);
    if (intLit(a) := el, intLit(b) := er) return intLit(a * b);
    return mulExpr(el, er);
}

Expression evalExpr(divExpr(l, r)) {
    Expression el = evalExpr(l);
    Expression er = evalExpr(r);
    if (intLit(a) := el, intLit(b) := er, b != 0) return intLit(a / b);
    return divExpr(el, er);
}

Expression evalExpr(modExpr(l, r)) {
    Expression el = evalExpr(l);
    Expression er = evalExpr(r);
    if (intLit(a) := el, intLit(b) := er, b != 0) return intLit(a % b);
    return modExpr(el, er);
}

Expression evalExpr(powExpr(l, r)) {
    Expression el = evalExpr(l);
    Expression er = evalExpr(r);
    if (intLit(base) := el, intLit(exp) := er) {
        int result = 1;
        for (_ <- [0 .. exp]) { result = result * base; }
        return intLit(result);
    }
    return powExpr(el, er);
}

Expression evalExpr(negExpr(e)) {
    return negExpr(evalExpr(e));
}

Expression evalExpr(implication(l, r)) {
    return implication(evalExpr(l), evalExpr(r));
}

Expression evalExpr(equivalence(l, r)) {
    return equivalence(evalExpr(l), evalExpr(r));
}

Expression evalExpr(orExpr(l, r)) {
    return orExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(andExpr(l, r)) {
    return andExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(eqExpr(l, r)) {
    return eqExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(ltExpr(l, r)) {
    return ltExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(gtExpr(l, r)) {
    return gtExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(lteExpr(l, r)) {
    return lteExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(gteExpr(l, r)) {
    return gteExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(neqExpr(l, r)) {
    return neqExpr(evalExpr(l), evalExpr(r));
}

Expression evalExpr(application(op, args)) {
    return application(op, [ evalExpr(a) | a <- args ]);
}

Expression evalExpr(quantifiedForall(v, d, body)) {
    return quantifiedForall(v, d, evalExpr(body));
}

Expression evalExpr(quantifiedExists(v, d, body)) {
    return quantifiedExists(v, d, evalExpr(body));
}

default Expression evalExpr(Expression e) = e;

// ============================================================
// Rule application (term rewriting)
// ============================================================

Expression applyAllRules(Expression expr, list[Rule] rules) {
    Expression current = expr;
    int maxIter = 100;
    for (_ <- [0 .. maxIter]) {
        Expression next = current;
        for (<lhs, rhs> <- rules) {
            next = applyRuleDeep(next, lhs, rhs);
        }
        if (next == current) return current;
        current = next;
    }
    return current;
}

Expression applyRuleDeep(Expression expr, OperatorApplication lhs, OperatorApplication rhs) {
    MR result = tryMatch(expr, lhs, ());
    if (result.ok) {
        return substituteOpApp(rhs, result.env);
    }
    return rewriteChildren(expr, lhs, rhs);
}

Expression rewriteChildren(Expression expr, OperatorApplication lhs, OperatorApplication rhs) {
    switch (expr) {
        case implication(l, r):  return implication(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case equivalence(l, r):  return equivalence(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case orExpr(l, r):       return orExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case andExpr(l, r):      return andExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case eqExpr(l, r):       return eqExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case ltExpr(l, r):       return ltExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case gtExpr(l, r):       return gtExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case lteExpr(l, r):      return lteExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case gteExpr(l, r):      return gteExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case neqExpr(l, r):      return neqExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case addExpr(l, r):      return addExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case subExpr(l, r):      return subExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case mulExpr(l, r):      return mulExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case divExpr(l, r):      return divExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case modExpr(l, r):      return modExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case powExpr(l, r):      return powExpr(applyRuleDeep(l, lhs, rhs), applyRuleDeep(r, lhs, rhs));
        case negExpr(e):         return negExpr(applyRuleDeep(e, lhs, rhs));
        case application(op, args):
            return application(op, [ applyRuleDeep(a, lhs, rhs) | a <- args ]);
        case quantifiedForall(v, d, body):
            return quantifiedForall(v, d, applyRuleDeep(body, lhs, rhs));
        case quantifiedExists(v, d, body):
            return quantifiedExists(v, d, applyRuleDeep(body, lhs, rhs));
    }
    return expr;
}

// ============================================================
// Pattern matching
// ============================================================

alias Env = map[str, Expression];
alias MR  = tuple[bool ok, Env env];

MR tryMatch(Expression expr, OperatorApplication pattern, Env env) {
    switch (expr) {
        case negExpr(e):
            return matchOpApp(operatorApplication("neg", [e]), pattern, env);
        case andExpr(l, r):
            return matchOpApp(operatorApplication("and", [l, r]), pattern, env);
        case orExpr(l, r):
            return matchOpApp(operatorApplication("or", [l, r]), pattern, env);
        case application(op, args):
            return matchOpApp(operatorApplication(op, args), pattern, env);
    }
    return <false, env>;
}

MR matchOpApp(OperatorApplication actual, OperatorApplication pattern, Env env) {
    if (actual.op != pattern.op) return <false, env>;
    if (size(actual.args) != size(pattern.args)) return <false, env>;
    for (i <- [0 .. size(actual.args)]) {
        <ok, env> = matchExpr(actual.args[i], pattern.args[i], env);
        if (!ok) return <false, env>;
    }
    return <true, env>;
}

MR matchExpr(Expression actual, Expression pattern, Env env) {
    if (idExpr(name) := pattern) {
        if (name in env) {
            return <env[name] == actual, env>;
        }
        return <true, env + (name: actual)>;
    }
    if (application(op1, args1) := actual, application(op2, args2) := pattern) {
        if (op1 != op2 || size(args1) != size(args2)) return <false, env>;
        for (i <- [0 .. size(args1)]) {
            <ok, env> = matchExpr(args1[i], args2[i], env);
            if (!ok) return <false, env>;
        }
        return <true, env>;
    }
    if (negExpr(e1) := actual, negExpr(e2) := pattern) {
        return matchExpr(e1, e2, env);
    }
    if (andExpr(l1, r1) := actual, andExpr(l2, r2) := pattern) {
        <ok, env> = matchExpr(l1, l2, env);
        if (!ok) return <false, env>;
        return matchExpr(r1, r2, env);
    }
    if (orExpr(l1, r1) := actual, orExpr(l2, r2) := pattern) {
        <ok, env> = matchExpr(l1, l2, env);
        if (!ok) return <false, env>;
        return matchExpr(r1, r2, env);
    }
    if (intLit(a) := actual, intLit(b) := pattern) {
        return <a == b, env>;
    }
    return <false, env>;
}

// ============================================================
// Substitution
// ============================================================

Expression substituteOpApp(OperatorApplication oa, Env env) {
    list[Expression] newArgs = [ substituteExpr(a, env) | a <- oa.args ];
    if (oa.op == "neg" && size(newArgs) == 1) return negExpr(newArgs[0]);
    if (oa.op == "and" && size(newArgs) == 2) return andExpr(newArgs[0], newArgs[1]);
    if (oa.op == "or"  && size(newArgs) == 2) return orExpr(newArgs[0], newArgs[1]);
    return application(oa.op, newArgs);
}

Expression substituteExpr(Expression expr, Env env) {
    switch (expr) {
        case idExpr(name): {
            if (name in env) return env[name];
            return expr;
        }
        case application(op, args):
            return application(op, [ substituteExpr(a, env) | a <- args ]);
        case negExpr(e):
            return negExpr(substituteExpr(e, env));
        case andExpr(l, r):
            return andExpr(substituteExpr(l, env), substituteExpr(r, env));
        case orExpr(l, r):
            return orExpr(substituteExpr(l, env), substituteExpr(r, env));
    }
    return expr;
}
