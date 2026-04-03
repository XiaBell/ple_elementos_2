module Parser

import Syntax;
import ParseTree;

public start[Program] parseProgram(str src, loc origin) 
    = parse(#start[Program], src, origin);

public start[Program] parseProgram(loc origin) 
    = parse(#start[Program], origin);
