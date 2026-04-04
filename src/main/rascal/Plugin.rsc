module Plugin

import IO;
import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Relation;

import Syntax;
import AST;
import Generator;

PathConfig pcfg = getProjectPathConfig(|project://ple_elementos_2|);
Language verilangLang = language(pcfg, "VeriLang", "alu", "Plugin", "contribs");

data Command = generateOutput(Program p);

set[LanguageService] contribs() = {
    parser(start[Program] (str program, loc src) {
        return parse(#start[Program], program, src);
    }),
    lenses(rel[loc src, Command lens] (start[Program] p) {
        return {
            <p.src, generateOutput(p.top)>
        };
    }),
    executor(exec)
};

value exec(generateOutput(Program p)) {
    rVal = generateFromAST(p);
    println(rVal);
    loc outputFile = |project://ple_elementos_2/instance/output/verilang-output.txt|;
    writeFile(outputFile, rVal);
    edit(outputFile);
    return ("result": true);
}

void main() {
    registerLanguage(verilangLang);
}
