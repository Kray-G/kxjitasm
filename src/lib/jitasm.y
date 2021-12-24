/* JIT assember */

%{
using @kacc.Lexer;
%}

%token CMD
%token FUNC LABEL IF
%token JMP CALL RET
%token MOV NEG CLZ
%token ADD SUB MUL DIV SDIV MOD SMOD
%token NOT AND OR XOR SHL LSHR ASHR
%token EQ NEQ GE LE GT LT SGE SLE SGT SLT
%token SREG RREG VAR ARG INT DBL
%token SW FP SIGNED OPEQ OPNEQ OPGE OPLE

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
    | alternatives '\n'
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

/* Lexical analyzer */
Jitasm.lexer = new Kacc.Lexer();
Jitasm.lexer.addSkip(/[ \t\r]+|#[^\r\n]+/);
Jitasm.lexer.addKeyword("==", OPEQ);
Jitasm.lexer.addKeyword("!=", OPNEQ);
Jitasm.lexer.addKeyword(">=", OPGE);
Jitasm.lexer.addKeyword("<=", OPLE);
Jitasm.lexer.addKeyword("if", IF);
Jitasm.lexer.addKeyword("signed", SIGNED);
Jitasm.lexer.addKeyword("func", FUNC);
Jitasm.lexer.addKeyword("goto", JMP) { &(yylval, token)
    yylval.value = JMP;
    yylval.name = "jmp";
    return token;
};
[
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
Jitasm.lexer.addRule(/\b[_a-zA-Z][_a-zA-Z0-9]*\b/, LABEL);
Jitasm.lexer.addRule(/[0-9]+(\.[0-9]+([eE][-+]?[0-9]+)?)?/) { &(yylval)
    if (yylval.value.find(".") > 0 || yylval.value.find("e") > 0 || yylval.value.find("E") > 0) {
        yylval.value = Double.parseDouble(yylval.value);
        return DBL;
    }
    yylval.value = Integer.parseInt(yylval.value);
    return INT;
};
// Jitasm.lexer.debugOn(Jitasm.lexer.DEBUG_TOKEN|Jitasm.lexer.DEBUG_VALUE);

using Jit;

class Jitasm(lexer_) {
    lexer_ ??= Jitasm.lexer;
    var labels_, pendings_, error_;
    var regs_ = {
        "R": [Jit.R0, Jit.R1, Jit.R2, Jit.R3, Jit.R4, Jit.R5],
        "S": [Jit.S0, Jit.S1, Jit.S2, Jit.S3, Jit.S4, Jit.S5],
        "FR": [Jit.FR0, Jit.FR1, Jit.FR2, Jit.FR3, Jit.FR4, Jit.FR5],
        "FS": [Jit.FS0, Jit.FS1, Jit.FS2, Jit.FS3, Jit.FS4, Jit.FS5],
    };

    private get(val) {
        if (val.type == "R" || val.type == "S") {
            var r = regs_[val.type][val.n];
            if (r.isUndefined) {
                throw RuntimeException("Invalid register");
            }
            return r;
        }
        if (val.type == "I") {
            return Jit.IMM(val.v);
        }
        throw RuntimeException("Invalid operand");
    }

    private comp(c, cmd, label, op1, op2) {
        var target = c[cmd](get(op1), get(op2));
        if (labels_[label].label) {
            target.setLabel(labels_[label].label);
        } else {
            pendings_.push((&(name, target) => {
                return function() {
                    if (labels_[name].label.isUndefined) {
                        throw RuntimeException("Function not found: " + name);
                    }
                    target.setLabel(labels_[name].label);
                };
            })(label, target));
        }
    }

    private calljmp(c, cmd, label, prop, msg) {
        if (labels_[label][prop]) {
            c[cmd](labels_[label][prop]);
        } else {
            var target = c[cmd]();
            pendings_.push((&(name, target) => {
                return function() {
                    if (labels_[name][prop].isUndefined) {
                        throw RuntimeException(msg);
                    }
                    target.setLabel(labels_[name][prop]);
                };
            })(label, target));
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

    private compile(list) {
        // list.each { System.println(_1.toJsonString()); };
        // return;

        var c = new Jit.Compiler();
        list.each {
            var ops = _1.operand;
            var op0 = ops[0];
            switch (_1.cmd) {
            case FUNC:
                if (labels_[op0.name].entry.isDefined) {
                    throw RuntimeException("Duplicated function name");
                }
                labels_[op0.name].entry = c.enter();
                break;
            case LABEL:
                if (labels_[op0.name].label.isUndefined) {
                    labels_[op0.name].label = c.label();
                }
                break;

            case JMP:
                checkOprands(_1, 1);
                calljmp(c, _1.name, op0.name, "label", "Label not found: " + op0.name);
                break;
            case CALL:
                checkOprands(_1, 1);
                calljmp(c, _1.name, op0.name, "entry", "Function not found: " + op0.name);
                break;

            case RET:
                gen1(c, _1.name, ops[0] ?? { type: "R", n: 0 });
                break;

            case ADD:
            case SUB:
            case MUL:
                checkOprands(_1, 3);
                gen3(c, _1.name, ops[0], ops[1], ops[2]);
                break;
            case DIV:
                checkOprands(_1, 0);
                c.div();
                break;
            case SDIV:
                checkOprands(_1, 0);
                c.sdiv();
                break;
            case MOD:
                checkOprands(_1, 0);
                c.divmod();
                break;
            case SMOD:
                checkOprands(_1, 0);
                c.sdivmod();
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

            case NEG:
            case CLZ:
            case NOT:
                checkOprands(_1, 1);
                gen1(c, _1.name, ops[0]);
                break;

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

    public parse(asmcode) {
        labels_ = [];
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
        parser.parse(asmcode, { &(r)
            ret = r;
        });
        if (!error_) {
            ret = compile(ret);
        }
        if (!error_) {
            return ret;
        }
    }

}
