module Implode

import Syntax;
import Parser;
import AST;

import ParseTree;
import Node;

public Program implodeProgram(Tree pt) = implode(#Program, pt);

public Program loadProgram(loc l) {
    start[Program] cst = parseProgram(l);
    return implodeProgram(cst.top);
}
