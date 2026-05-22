module RunnerJson

import IO;
import List;
import String;
import Implode;
import TypeCheck;
import AST;
import util::SystemAPI;

// Genera instance/output/verilang-ast.json (AST + resultado del análisis)

str esc(str s) =
    replaceAll(replaceAll(replaceAll(replaceAll(
        s, "\\", "\\\\"), "\"", "\\\""), "\n", "\\n"), "\t", "\\t");

str jsonArr(list[str] items) =
    "[<intercalate(", ", [ "\"<esc(i)>\"" | i <- items ])>]";

str jsonResult(
    bool success,
    list[str] modules,
    bool parseOk,
    bool tcOk,
    list[str] tcErrs,
    str err,
    str resumen
) =
    "{\"success\":<success>,"
    + "\"module\":\"<esc(size(modules) > 0 ? modules[0] : "")>\","
    + "\"modules\":<jsonArr(modules)>,"
    + "\"parseOk\":<parseOk>,"
    + "\"typeCheckOk\":<tcOk>,"
    + "\"semanticOk\":<tcOk>,"
    + "\"typeErrors\":<jsonArr(tcErrs)>,"
    + "\"semanticErrors\":[],"
    + "\"output\":[],"
    + "\"error\":\"<esc(err)>\","
    + "\"codigoFormateado\":\"\","
    + "\"resumen\":\"<esc(resumen)>\"}";

loc inputLoc(str path) {
    str n = replaceAll(path, "\\", "/");
    if (size(n) > 0 && startsWith(n, "/")) return |file:///| + substring(n, 1);
    if (/^[a-zA-Z]:\/.*/ := n) return |file:///| + n;
    return |file:///| + getSystemProperty("user.dir") + "/" + n;
}

list[str] moduleNames(Module m) =
    [m.name] + [n | usingDecl(n) <- m.usings];

str buildResumen(Module m) {
    int nSpaces = (0 | 1 | spaceDeclElem(_) <- m.elements);
    int nOps    = (0 | 1 | operatorDeclElem(_) <- m.elements);
    int nVars   = (0 | 1 | varDeclElem(_) <- m.elements);
    int nData   = (0 | 1 | dataDeclElem(_) <- m.elements);
    int nRules  = (0 | 1 | ruleDeclElem(_) <- m.elements);
    int nExprs  = (0 | 1 | expressionDeclElem(_) <- m.elements);
    return "espacios: <nSpaces>, operadores: <nOps>, variables: <nVars>, defdata: <nData>, reglas: <nRules>, expresiones: <nExprs>";
}

void writeAstJson(str jsonBody) {
    loc out = |file:///| + getSystemProperty("user.dir") + "/instance/output/verilang-ast.json";
    writeFile(out, jsonBody);
}

void main(list[str] args) {
    if (isEmpty(args)) {
        writeAstJson(jsonResult(false, [], false, false, [], "Falta ruta del archivo .vl", ""));
        return;
    }

    loc file = inputLoc(args[0]);

    try {
        ast = loadProgram(file);
        m = ast.moduleDef;
        list[str] mods = moduleNames(m);
        str resumen = buildResumen(m);

        TcResult tc = typeCheck(ast);
        list[str] tcErrs = [msg | msg <- tc.messages];

        if (!tc.ok) {
            writeAstJson(jsonResult(false, mods, true, false, tcErrs, "", resumen));
            return;
        }

        writeAstJson(jsonResult(true, mods, true, true, [], "", resumen));
    } catch ParseError(loc at): {
        writeAstJson(jsonResult(false, [], false, false, [], "Error de parsing en <at>", ""));
    } catch err: {
        str msg = "<err>";
        bool afterParse = contains(msg, "implode") || contains(msg, "AST");
        writeAstJson(jsonResult(false, [], !afterParse, false, [], msg, ""));
    }
}
