/* JIT assember */

%{
using @kacc.Lexer;
%}

%token LOAD DATA STR
%token CMD
%token FUNC LIB LABEL IF
%token JMP CALL RET
%token FMOV32 FMOV
%token MOV8S MOV16S MOV32S MOV8 MOV16 MOV32 MOV
%token NOT32 NEG32 CLZ32 NOT NEG CLZ
%token ADD32 SUB32 MUL32 DIV32 SDIV32 MOD32 SMOD32 AND32 OR32 XOR32 SHL32 LSHR32 ASHR32
%token ADD SUB MUL DIV SDIV MOD SMOD AND OR XOR SHL LSHR ASHR
%token EQ NEQ GE LE GT LT SGE SLE SGT SLT
%token SREG RREG VAR ARG INT DBL
%token SIGNED OPEQ OPNEQ OPGE OPLE

%%

start:    lines;

lines
    : line { $1.line = @getLine(); $$ = [$1]; @nextLine(); }
    | lines line { $2.line = @getLine(); if ($2.isDefined) $$.push($2); @nextLine(); }
    ;

line
    : '\n' /* empty line */ { $$ = null; }
    | LABEL ':' '\n' { $$ = { "cmd": LABEL, "name": "label", "operand": [{ "name": $1.value }] }; }
    | FUNC LABEL '\n' { $$ = { "cmd": FUNC, "name": "func", "operand": [{ "name": $2.value }] }; }
    | CMD operands_Opt '\n' { $$ = { "cmd": $1.value, "name": $1.name, "operand": $2 }; }
    | JMP LABEL '\n' { $$ = { "cmd": JMP, "name": "jmp", "operand": [{ "name": $2.value }] }; }
    | LOAD FUNC LABEL { $$ = { "cmd": LOAD, "name": "load", "operand": [{ "type": FUNC, "name": $3.value }] }; }
    | LOAD LIB LABEL { $$ = { "cmd": LOAD, "name": "load", "operand": [{ "type": LIB, "name": $3.value }] }; }
    | DATA '@' LABEL data { $$ = { "cmd": DATA, "name": "data", "operand": [{ "name": $3.value, "value": $4.value }] }; }
    | alternatives '\n'
    | error '\n' { $$.error = true; }
    ;

data
    : STR
    | '<' values '>' { $$.value = <...$2>; }
    ;

values
    : INT { $$ = [$1.value]; }
    | values ',' INT { $$.push($3.value); }
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
    | '[' SREG offset_Opt ']' { $$ = { "type": "DS", "n": $2.value, "offset": $3.value }; }
    | '[' RREG offset_Opt ']' { $$ = { "type": "DR", "n": $2.value, "offset": $3.value }; }
    | INT { $$ = { "type": "I", "v": $1.value }; }
    | DBL { $$ = { "type": "D", "v": $1.value }; }
    | VAR '[' INT ']' { $$ = { "type": "V", "offset": $3.value }; }
    | ARG '[' INT ']' { $$ = { "type": "A", "offset": $3.value }; }
    | LABEL { $$ = { "type": "L", "name": $1.value }; }
    | '@' LABEL { $$ = { "type": "A", "name": $2.value }; }
    ;

offset_Opt
    : /* empty */ { $$.value = 0; }
    | '+' INT { $$.value = $2.value; }
    ;

alternatives
    : IF operand OPEQ operand JMP LABEL { $$ = { "cmd": EQ, "name": "eq", "operand": [{ "type": "L", "name": $6.value }, $2, $4] }; }
    | IF operand OPNEQ operand JMP LABEL { $$ = { "cmd": NEQ, "name": "neq", "operand": [{ "type": "L", "name": $6.value }, $2, $4] }; }
    | IF operand OPGE operand JMP LABEL { $$ = { "cmd": GE, "name": "ge", "operand": [{ "type": "L", "name": $6.value }, $2, $4] }; }
    | IF operand OPLE operand JMP LABEL { $$ = { "cmd": LE, "name": "le", "operand": [{ "type": "L", "name": $6.value }, $2, $4] }; }
    | IF operand '>' operand JMP LABEL { $$ = { "cmd": GT, "name": "gt", "operand": [{ "type": "L", "name": $6.value }, $2, $4] }; }
    | IF operand '<' operand JMP LABEL { $$ = { "cmd": LT, "name": "lt", "operand": [{ "type": "L", "name": $6.value }, $2, $4] }; }
    | IF SIGNED operand OPGE operand JMP LABEL { $$ = { "cmd": SGE, "name": "sge", "operand": [{ "type": "L", "name": $7.value }, $3, $5] }; }
    | IF SIGNED operand OPLE operand JMP LABEL { $$ = { "cmd": SLE, "name": "sle", "operand": [{ "type": "L", "name": $7.value }, $3, $5] }; }
    | IF SIGNED operand '>' operand JMP LABEL { $$ = { "cmd": SGT, "name": "sgt", "operand": [{ "type": "L", "name": $7.value }, $3, $5] }; }
    | IF SIGNED operand '<' operand JMP LABEL { $$ = { "cmd": SLT, "name": "slt", "operand": [{ "type": "L", "name": $7.value }, $3, $5] }; }
    ;

%%

using Jit;

class Jitasm(opts_) {
    var lexer_, code_;
    var loaded_, data_, entries_, funcname_, pendings_, error_;
    var regs_ = {
        "R": [Jit.R0, Jit.R1, Jit.R2, Jit.R3, Jit.R4, Jit.R5],
        "S": [Jit.S0, Jit.S1, Jit.S2, Jit.S3, Jit.S4, Jit.S5],
        "FR": [Jit.FR0, Jit.FR1, Jit.FR2, Jit.FR3, Jit.FR4, Jit.FR5],
        "FS": [Jit.FS0, Jit.FS1, Jit.FS2, Jit.FS3, Jit.FS4, Jit.FS5],
    };

    private initialize() {
        /* Lexical analyzer */
        lexer_ = new Kacc.Lexer();
        lexer_.addSkip(/[ \t\r]+|#[^\r\n]+/);
        lexer_.addKeyword("load", LOAD);
        lexer_.addKeyword("data", DATA);
        lexer_.addKeyword("==", OPEQ);
        lexer_.addKeyword("!=", OPNEQ);
        lexer_.addKeyword(">=", OPGE);
        lexer_.addKeyword("<=", OPLE);
        lexer_.addKeyword("if", IF);
        lexer_.addKeyword("signed", SIGNED);
        lexer_.addKeyword("func", FUNC);
        lexer_.addKeyword("lib", LIB);
        lexer_.addKeyword("var", VAR);
        lexer_.addKeyword("arg", ARG);
        lexer_.addKeyword("goto", JMP) { &(yylval, token)
            yylval.value = JMP;
            yylval.name = "jmp";
            return token;
        };
        [
            { "value": JMP,    "name": "jmp"       },
            { "value": CALL,   "name": "call"      },
            { "value": RET,    "name": "ret"       },

            { "value": MOV8S,  "name": "mov8s"     },
            { "value": MOV16S, "name": "mov16s"    },
            { "value": MOV32S, "name": "mov32s"    },
            { "value": MOV8,   "name": "mov8"      },
            { "value": MOV16,  "name": "mov16"     },
            { "value": MOV32,  "name": "mov32"     },
            { "value": MOV,    "name": "mov"       },
            { "value": FMOV32, "name": "fmov32"    },
            { "value": FMOV,   "name": "fmov"      },

            { "value": NOT32,  "name": "not32"     },
            { "value": NEG32,  "name": "neg32"     },
            { "value": CLZ32,  "name": "clz32"     },
            { "value": NOT,    "name": "not"       },
            { "value": NEG,    "name": "neg"       },
            { "value": CLZ,    "name": "clz"       },

            { "value": ADD32,  "name": "add32"     },
            { "value": SUB32,  "name": "sub32"     },
            { "value": MUL32,  "name": "mul32"     },
            { "value": DIV32,  "name": "div32"     },
            { "value": SDIV32, "name": "sdiv32"    },
            { "value": MOD32,  "name": "divmod32"  },
            { "value": SMOD32, "name": "sdivmod32" },
            { "value": SHL32,  "name": "shl32"     },
            { "value": LSHR32, "name": "lshr32"    },
            { "value": ASHR32, "name": "ashr32"    },
            { "value": ADD,    "name": "add"       },
            { "value": SUB,    "name": "sub"       },
            { "value": MUL,    "name": "mul"       },
            { "value": DIV,    "name": "div"       },
            { "value": SDIV,   "name": "sdiv"      },
            { "value": MOD,    "name": "divmod"    },
            { "value": SMOD,   "name": "sdivmod"   },
            { "value": SHL,    "name": "shl"       },
            { "value": LSHR,   "name": "lshr"      },
            { "value": ASHR,   "name": "ashr"      },

            { "value": EQ,     "name": "eq"        },
            { "value": NEQ,    "name": "neq"       },
            { "value": GE,     "name": "ge"        },
            { "value": LE,     "name": "le"        },
            { "value": GT,     "name": "gt"        },
            { "value": LT,     "name": "lt"        },
            { "value": SGE,    "name": "sge"       },
            { "value": SLE,    "name": "sle"       },
            { "value": SGT,    "name": "sgt"       },
            { "value": SLT,    "name": "slt"       },
        ].each {
            var key = _1;
            lexer_.addKeyword(_1.name, CMD) { &(yylval, token)
                yylval.value = key.value;
                yylval.name = key.name;
                return token;
            };
        };

        lexer_.addRule(/\br([0-9]+)\b/, RREG) { &(value)
            return Integer.parseInt(value.subString(1));
        };
        lexer_.addRule(/\bs([0-9]+)\b/, SREG) { &(value)
            return Integer.parseInt(value.subString(1));
        };
        lexer_.addRule(/"([^\"]|\\.)*"/, STR) { &(value)
            return value.subString(1, value.length() - 2).replace(/\\(.)/, &(g) => {
                var c = g[1].string;
                if (c == 'n') {
                    return '\n';
                }
                if (c == 'r') {
                    return '\r';
                }
                if (c == 't') {
                    return '\t';
                }
                return c;
            });
        };
        lexer_.addRule(/\b[_a-zA-Z][_a-zA-Z0-9]*\b/, LABEL);
        lexer_.addRule(/0b[0-9a-fA-F]+|0x[0-9a-fA-F]+|0[0-7]*/, INT) { &(value)
            return Integer.parseInt(value);
        };
        lexer_.addRule(/[1-9][0-9]*(\.[0-9]+([eE][-+]?[0-9]+)?)?/) { &(yylval)
            if (yylval.value.find(".") > 0 || yylval.value.find("e") > 0 || yylval.value.find("E") > 0) {
                yylval.value = Double.parseDouble(yylval.value);
                return DBL;
            }
            yylval.value = Integer.parseInt(yylval.value);
            return INT;
        };
        if (opts_.debug.lexer) {
            lexer_.debugOn(lexer_.DEBUG_TOKEN|lexer_.DEBUG_VALUE);
        }
    }

    private get(val) {
        if (val.type == "A") {
            if (data_[val.name].isUndefined) {
                throw RuntimeException("Undefined data: " + val.name);
            }
            return data_[val.name];
        }
        if (val.type == "I" || val.type == "D") {
            return Jit.IMM(val.v);
        }
        if (val.type == "R" || val.type == "S") {
            var r = regs_[val.type][val.n];
            if (r.isUndefined) {
                throw RuntimeException("Invalid register");
            }
            return r;
        }
        if (val.type == "DR" || val.type == "DS") {
            var r = regs_[val.type == "DR" ? "R" : "S"][val.n];
            if (r.isUndefined) {
                throw RuntimeException("Invalid register");
            }
            return Jit.MEM1(r, val.offset);
        }
        throw RuntimeException("Invalid operand");
    }

    private comp(c, cmd, label, op1, op2) {
        var target = c[cmd](get(op1), get(op2));
        var jumpto = entries_[funcname_].labels[label];
        if (jumpto) {
            target.setLabel(jumpto);
        } else {
            pendings_.push((&(funcname, label, target) => {
                return function() {
                    var jumpto = entries_[funcname].labels[label];
                    if (jumpto.isUndefined) {
                        throw RuntimeException("Label not found: " + label + " in " + funcname);
                    }
                    target.setLabel(jumpto);
                };
            })(funcname_, label, target));
        }
    }

    private gen1(c, cmd, op1) {
        c[cmd](get(op1));
    }

    private gen2(c, cmd, op1, op2) {
        c[cmd](get(op1), get(op2));
    }

    private gen3(c, cmd, op1, op2, op3) {
        c[cmd](get(op1), get(op2), get(op3));
    }

    private checkOprands(line, count) {
        var opslen = line.operand.length();
        if (opslen < count) {
            System.println("Operands are not enough at line %{line.line}");
            error_ = true;
        }
        if (opslen > count) {
            System.println("Too many operands at line %{line.line}");
            error_ = true;
        }
    }

    private jitCompile(list) {
        // list.each { System.println(_1.toJsonString()); };
        // return;

        var c = new Jit.Compiler();
        list.each {
            var ops = _1.operand;
            var op0 = ops[0];
            switch (_1.cmd) {
            case LOAD:
                if (op0.type == LIB) {
                    Jit.Clib.addlib(op0.name);
                } else if (op0.type == FUNC) {
                    loaded_[op0.name] = Jit.Clib.load(op0.name);
                    if (!loaded_[op0.name]) {
                        throw RuntimeException("Loading a function failed: " + op0.name);
                    }
                } else {
                    throw RuntimeException("Invalid load type");
                }
                break;
            case DATA:
                if (op0.value.isString || op0.value.isBinary) {
                    data_[op0.name] = op0.value;
                } else {
                    throw RuntimeException("Invalid data type");
                }
                break;

            case FUNC:
                funcname_ = op0.name;
                if (entries_[funcname_].entry.isDefined) {
                    throw RuntimeException("Duplicated function name");
                }
                entries_[funcname_].entry = c.enter();
                entries_[funcname_].labels = {};
                break;
            case LABEL:
                if (entries_[funcname_].labels[op0.name].isUndefined) {
                    entries_[funcname_].labels[op0.name] = c.label();
                }
                break;

            case JMP:
                checkOprands(_1, 1);
                var jumpto = entries_[funcname_].labels[op0.name];
                if (jumpto) {
                    c.jump(jumpto);
                } else {
                    var target = c.jmp();
                    pendings_.push((&(funcname, label, target) => {
                        return function() {
                            var jumpto = entries_[funcname].labels[label];
                            if (jumpto.isUndefined) {
                                throw RuntimeException("Label not found: " + label + " in " + funcname);
                            }
                            target.setLabel(jumpto);
                        };
                    })(funcname_, op0.name, target));
                }
                break;
            case CALL:
                checkOprands(_1, 1);
                if (loaded_[op0.name]) {
                    c.icall(loaded_[op0.name]);
                } else {
                    var entry = entries_[op0.name].entry;
                    if (entry) {
                        c.call(entry);
                    } else {
                        var target = c.call();
                        pendings_.push((&(name, target) => {
                            return function() {
                                if (entries_[name].entry.isUndefined) {
                                    throw RuntimeException("Function not found: " + name);
                                }
                                target.setLabel(entries_[name].entry);
                            };
                        })(op0.name, target));
                    }
                }
                break;

            case RET:
                gen1(c, _1.name, ops[0] ?? { type: "R", n: 0 });
                break;

            case ADD32:
            case SUB32:
            case MUL32:
            case DIV32:
            case SDIV32:
            case MOD32:
            case SMOD32:
            case ADD:
            case SUB:
            case DIV:
            case SDIV:
            case MOD:
            case SMOD:
            case MUL:
                checkOprands(_1, 3);
                gen3(c, _1.name, ops[0], ops[1], ops[2]);
                break;

            case EQ:
            case NEQ:
            case GE:
            case LE:
            case GT:
            case LT:
            case SGE:
            case SLE:
            case SGT:
            case SLT:
                checkOprands(_1, 3);
                comp(c, _1.name, op0.name, ops[1], ops[2]);
                break;

            case NEG32:
            case CLZ32:
            case NOT32:
            case NEG:
            case CLZ:
            case NOT:
                checkOprands(_1, 1);
                gen1(c, _1.name, ops[0]);
                break;

            case MOV8S:
            case MOV16S:
            case MOV32S:
            case MOV8:
            case MOV16:
            case MOV32:
            case FMOV32:
            case FMOV:
            case AND32:
            case OR32:
            case XOR32:
            case SHL32:
            case LSHR32:
            case ASHR32:
            case MOV:
            case AND:
            case OR:
            case XOR:
            case SHL:
            case LSHR:
            case ASHR:
                checkOprands(_1, 2);
                gen2(c, _1.name, ops[0], ops[1]);
                break;

            default:
                break;
            }
        };

        pendings_.each { => _1() };
        return c.generate();
    }

    public dump(list) {
        if (!code_) {
            code_ = jitCompile(list);
        }
        code_.dump();
        return 0;
    }

    public run(list) {
        if (!code_) {
            code_ = jitCompile(list);
        }
        return code_.run();
    }

    public parse(asmcode) {
        entries_ = [];
        pendings_ = [];
        error_ = false;

        /* Parser */
        var lineNumber = 1;
        var parser = new Kacc.Parser(lexer_, {
            yyerror: &(msg) => {
                System.println(("ERROR! " + msg + " at line %{lineNumber}").red().bold());
                error_ = true;
            },
            nextLine: &() => {
                ++lineNumber;
            },
            getLine: &() => {
                return lineNumber;
            },
        });

        var ret;
        parser.parse(asmcode.trimRight() + '\n', { &(r)
            ret = r;
        });

        if (!error_) {
            return ret;
        }
    }

}
