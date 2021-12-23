/* Calculator in Kacc. */

%{
using @kacc.Lexer;
%}

%token CMD
%token FUNC LABEL
%token JMP CALL RET
%token MOV NEG CLZ
%token ADD SUB MUL DIV SDIV MOD SMOD
%token NOT AND OR XOR SHL LSHR ASHR
%token EQ NEQ GE LE GT LT SGE SLE SGT SLT
%token SREG RREG VAR ARG INT DBL

%%

start:    lines;

lines
    : line { $$ = [$1]; }
    | lines line { $$.push($2); }
    ;

line
    : CMD operands_Opt '\n' { $$ = { "cmd": $1.value, "name": $1.name, "operand": $2 }; }
    | LABEL ':' '\n' { $$ = { "cmd": LABEL, "name": "label", "operand": [{ "name": $1.value }] }; }
    | error '\n' { $$.error = true; }
    ;

operands_Opt
    : /* empty */ { $$ = []; }
    | operands
    ;

operands
    : operand { $$ = [$1]; }
    | operands ',' operand { $$.push($3); }
    ;

operand
    : SREG { $$ = { "type": "S", "n": $1.value }; }
    | RREG { $$ = { "type": "R", "n": $1.value }; }
    | INT { $$ = { "type": "I", "v": $1.value }; }
    | DBL { $$ = { "type": "D", "v": $1.value }; }
    | VAR '[' INT ']' { $$ = { "type": "V", "offset": $3.value }; }
    | ARG '[' INT ']' { $$ = { "type": "A", "offset": $3.value }; }
    | LABEL { $$ = { "type": "L", "name": $1.value }; }
    ;

%%

/* Lexical analyzer */
Jitasm.lexer = new Kacc.Lexer();
Jitasm.lexer.addSkip(/[ \t\r]+|#[^\r\n]+/);
[
    { "value": FUNC, "name": "func" },
    { "value": JMP,  "name": "jmp"  },
    { "value": CALL, "name": "call" },
    { "value": RET,  "name": "ret"  },
    { "value": MOV,  "name": "mov"  },
    { "value": NEG,  "name": "neg"  },
    { "value": CLZ,  "name": "clz"  },
    { "value": ADD,  "name": "add"  },
    { "value": SUB,  "name": "sub"  },
    { "value": MUL,  "name": "mul"  },
    { "value": DIV,  "name": "div"  },
    { "value": SDIV, "name": "sdiv" },
    { "value": MOD,  "name": "mod"  },
    { "value": SMOD, "name": "smod" },
    { "value": MOD,  "name": "mod"  },
    { "value": SHL,  "name": "shl"  },
    { "value": LSHR, "name": "lshr" },
    { "value": ASHR, "name": "ashr" },
    { "value": EQ,   "name": "eq"   },
    { "value": NEQ,  "name": "neq"  },
    { "value": GE,   "name": "ge"   },
    { "value": LE,   "name": "le"   },
    { "value": GT,   "name": "gt"   },
    { "value": LT,   "name": "lt"   },
    { "value": SGE,  "name": "sge"  },
    { "value": SLE,  "name": "sle"  },
    { "value": SGT,  "name": "sgt"  },
    { "value": SLT,  "name": "slt"  },
].each {
    var key = _1;
    Jitasm.lexer.addKeyword(_1.name, CMD) { &(yylval, token)
        yylval.value = key.value;
        yylval.name = key.name;
        return token;
    };
};

Jitasm.lexer.addRule(/var/, VAR);
Jitasm.lexer.addRule(/arg/, ARG);
Jitasm.lexer.addRule(/\br([0-9]+)\b/, RREG) { &(value)
    return Integer.parseInt(value.subString(1));
};
Jitasm.lexer.addRule(/\bs([0-9]+)\b/, SREG) { &(value)
    return Integer.parseInt(value.subString(1));
};
Jitasm.lexer.addRule(/\b[a-zA-Z][a-zA-Z0-9]*\b/, LABEL);
Jitasm.lexer.addRule(/[0-9]+(\.[0-9]+([eE][-+]?[0-9]+)?)?/) { &(yylval)
    if (yylval.value.find(".") > 0 || yylval.value.find("e") > 0 || yylval.value.find("E") > 0) {
        yylval.value = Double.parseDouble(yylval.value);
        return DBL;
    }
    yylval.value = Integer.parseInt(yylval.value);
    return INT;
};

using @jitasm._JitasmBase;

