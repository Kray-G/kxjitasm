# Jit Assembler

## Background

As far as I can see the JIT world, most of JIT assembler is not portable. It means a JIT assembler is suited only to a specific platform like x86, x64, arm, or something like that. Therefore, a JIT assembler for x64 that you are using can not be used for the other platform. When you want to use it for the arm platform, you have to make it another way and it is very tough activity.

This JIT assembler's purpose is to make it portable. By abstracted assembly language, it makes that you can write it once and use it anywhere. Of course, it has a limitation to suit to various platforms, but by that it will make it more reasonable.

## Installation

Use `kip` to install this Jit Assembler because this is provided as a package of `Kinx`. Install this by the following command.

```
$ kip install jitasm
```

# Abstracted Assembly Language (LIR)

It is based on the SLJIT library. In the lower level IR is almost all corresponding to the SLJIT functions. Additionally, there are some representations over the SLJIT world, and by that, it will be more useful.

## Structure

Roughly the structure is like the following.

* Line Oriented
  * A labe, a command, or something instructions will be written in line by line.
* Label
  * It is a `LABEL:` style and it means a location mark like a destination of jump.
* Function Entry Point
  * This is like a label, but it only means an entry point to a function.
  * The special entry point of `main` is needed.
    * The `main` will work like `int main(int argc, char** argv)` in C.
    * `argc` is passed to the register of `s0`, and `argv` is passed to the register of `s1`.
    * The address is stored with 8 bytes, so the address to the 1st argument will be `[s1]`, and the 2nd argument will be `[s1+8]`.
* Instructions
  * Instructions are mostly defined just corresponding to a function in SLJIT.
* Alternative Representation
  * It would be more readable for the human.
* Comment
  * A comment will be started with `#` and it is continued until the end of line.

### Example

#### Fibonacci Number

Here is a fibonacci number calculation.

```asm
func fib
    sge label1, s0, 3
    # if signed s0 >= 3 goto next
    ret s0
  next:
    sub r0, s0, 2
    call fib
    mov s1, r0
    sub r0, s0, 1
    call fib
    add r0, r0, s1
    ret
```

#### Call C Runtime

Although it has a limitation, you can use C Runtime functions. The limitation is to be able to use only 3 arguments of unsigned integers. For example, you can use `printf` if it is 3 arguments as below. By the way, this code is assumed to be used with the above fib code.

```asm
load func printf
@fmt "fib(%lld) = %lld\n"

func main
    mov s0, 1
    goto loop
  next:
    mov r0, s0
    call fib
    mov r2, r0
    mov r1, s0
    mov r0, @fmt
    call printf
    add s0, s0, 1
  loop:
    if s0 <= 42 goto next
    ret
```

## Mnemonic

### Label and Function Entry Point

The label is started with the label name, and `:` is following the name. See below. Note that the label is available only in the function scope. It means that you can use the same label name in a different function.

```
labelname:
```

The function entry point is started with `func`, and the entry name will follow that. See the example below for how to write it.

```
func entryname
```

### Independent Instructions

You can use the following instructions independent of a function scope.

|  Instruction  |  Operands  |               Meaning                |                     Remark                     |
| ------------- | ---------- | ------------------------------------ | ---------------------------------------------- |
| `load` `func` | NAME       | Load a function as a C function.     | The search library is CRT by default.          |
| `load` `lib`  | NAME       | Load and add a dynamic link library. | This library is added to the search library.   |
| `@`           | LABEL DATA | A constant data store.               | As DATA, it is supported a string or a binary. |

Regarding a constant data store, there are following rules.

* LABEL should be used with `@` plus LABEL like `@fmt`.
* A string should be `"..."` style, and a binary should be `<...>` style.

### Instructions

Instructions can be described as below. Some operands will follow the instruction name with separated by comma.

```
instruction operand1, operand2, ...
```

The following table shows the list of mnemonic in this JIT assembler.

| Instruction |    Operands     |                        Meaning                        |                   Remark                   |
| ----------- | --------------- | ----------------------------------------------------- | ------------------------------------------ |
| `localbase` | REG (, index)   | Store the address of a local variable to REG.         | Omitting an index means zero.              |
| `jmp`       | LABEL           | Jump to the label.                                    | `goto` is also available instead of `jmp`. |
| `call`      | ENTRY           | Call a function.                                      |                                            |
| `ret`       | (VAL/REG)       | Return VAL from a function.                           | if VAL/REG is omitted, returns `r0`.       |
| `mov`       | DST, SRC        | Move SRC to DST.                                      |                                            |
| `not`       | TGT             | Bitwise NOT.                                          |                                            |
| `neg`       | TGT             | Make negative.                                        |                                            |
| `clz`       | TGT             | Count a zero bit.                                     |                                            |
| `add`       | DST, OP1, OP2   | DST := OP1 + OP2                                      |                                            |
| `sub`       | DST, OP1, OP2   | DST := OP1 - OP2                                      |                                            |
| `mul`       | DST, OP1, OP2   | DST := OP1 \* OP2                                     |                                            |
| `div`       | DST, OP1, OP2   | DST := OP1 / OP2                                      |                                            |
| `sdiv`      | DST, OP1, OP2   | DST := OP1 / OP2 (signed)                             |                                            |
| `mod`       | DST, OP1, OP2   | DST := OP1 % OP2                                      |                                            |
| `smod`      | DST, OP1, OP2   | DST := OP1 % OP2 (signed)                             |                                            |
| `and`       | DST, OP1, OP2   | DST := OP1 & OP2                                      |                                            |
| `or`        | DST, OP1, OP2   | DST := OP1 <code>&#124;</code> OP2                    |                                            |
| `xor`       | DST, OP1, OP2   | DST := OP1 ^ OP2                                      |                                            |
| `shl`       | DST, OP1, OP2   | DST := OP1 \<\< OP2                                   |                                            |
| `lshr`      | DST, OP1, OP2   | DST := OP1 \>\> OP2 (logical)                         |                                            |
| `ashr`      | DST, OP1, OP2   | DST := OP1 \>\> OP2 (arithmetic)                      |                                            |
| `eq`        | LABEL, OP1, OP2 | if OP1 == OP2, jump to LABEL                          |                                            |
| `neq`       | LABEL, OP1, OP2 | if OP1 != OP2, jump to LABEL                          |                                            |
| `ge`        | LABEL, OP1, OP2 | if OP1 \>= OP2, jump to LABEL                         |                                            |
| `le`        | LABEL, OP1, OP2 | if OP1 \<= OP2, jump to LABEL                         |                                            |
| `gt`        | LABEL, OP1, OP2 | if OP1 \> OP2, jump to LABEL                          |                                            |
| `lt`        | LABEL, OP1, OP2 | if OP1 \< OP2, jump to LABEL                          |                                            |
| `sge`       | LABEL, OP1, OP2 | if OP1 \>= OP2, jump to LABEL (comparing with signed) |                                            |
| `sle`       | LABEL, OP1, OP2 | if OP1 \<= OP2, jump to LABEL (comparing with signed) |                                            |
| `sgt`       | LABEL, OP1, OP2 | if OP1 \> OP2, jump to LABEL (comparing with signed)  |                                            |
| `slt`       | LABEL, OP1, OP2 | if OP1 \< OP2, jump to LABEL (comparing with signed)  |                                            |
| `mov8`      | DST, SRC        | Move SRC to DST.                                      | for 8 bit                                  |
| `mov16`     | DST, SRC        | Move SRC to DST.                                      | for 16 bit                                 |
| `mov32`     | DST, SRC        | Move SRC to DST.                                      | for 32 bit                                 |
| `mov8s`     | DST, SRC        | Move SRC to DST.                                      | for signed 8 bit                           |
| `mov16s`    | DST, SRC        | Move SRC to DST.                                      | for signed 16 bit                          |
| `mov32s`    | DST, SRC        | Move SRC to DST.                                      | for signed 32 bit                          |
| `not32`     | TGT             | Bitwise NOT.                                          | for 32 bit                                 |
| `neg32`     | TGT             | Make negative.                                        | for 32 bit                                 |
| `clz32`     | TGT             | Count a zero bit.                                     | for 32 bit                                 |
| `add32`     | DST, OP1, OP2   | DST := OP1 + OP2                                      | for 32 bit                                 |
| `sub32`     | DST, OP1, OP2   | DST := OP1 - OP2                                      | for 32 bit                                 |
| `mul32`     | DST, OP1, OP2   | DST := OP1 \* OP2                                     | for 32 bit                                 |
| `div32`     | DST, OP1, OP2   | DST := OP1 / OP2                                      | for 32 bit                                 |
| `sdiv32`    | DST, OP1, OP2   | DST := OP1 / OP2 (signed)                             | for 32 bit                                 |
| `mod32`     | DST, OP1, OP2   | DST := OP1 % OP2                                      | for 32 bit                                 |
| `smod32`    | DST, OP1, OP2   | DST := OP1 % OP2 (signed)                             | for 32 bit                                 |
| `and32`     | DST, OP1, OP2   | DST := OP1 & OP2                                      | for 32 bit                                 |
| `or32`      | DST, OP1, OP2   | DST := OP1 <code>&#124;</code> OP2                    | for 32 bit                                 |
| `xor32`     | DST, OP1, OP2   | DST := OP1 ^ OP2                                      | for 32 bit                                 |
| `shl32`     | DST, OP1, OP2   | DST := OP1 \<\< OP2                                   | for 32 bit                                 |
| `lshr32`    | DST, OP1, OP2   | DST := OP1 \>\> OP2 (logical)                         | for 32 bit                                 |
| `ashr32`    | DST, OP1, OP2   | DST := OP1 \>\> OP2 (arithmetic)                      | for 32 bit                                 |

### Operand

The operand will be a register, a memory addressing, an immediate value, a data label, or a variable.

A register is represented by `s` or `r` with the number such as `s0`. The number should be represented from 0 to 6 for each. The register of `s` means a saved register, that is why the value in a register will be saved even after calling another function. However, when it is the register of `r`, it means a scratch register, so it might be destroyed when calling another function.

Arounding `[` and `]` means a memory addressing way, and you can put a register and its offset between `[` and `]` like `[s0 + 8]`. An immediate value is like just 0, 1, 100, 0.1, 0.2, or something like that. It is needed to be an integer or a double precision value. A data label is like `@fmt`, and it will be started with `@` and the label name will follow it. This label should be defined former than using it.

A variable is written like `var[N]`, and `N` should be an integer value. The variable area will be automatically reserved in use. So if you want to reserve the area of variables that you are going to use in advance, you can do the following.

```asm
    mov r0, var[10]     # Reserved an area of 10 variables in advance.
```

Also if you want to use a register as an offset to access the variable, you can use a `localbase` instruction. Here is an example.

```asm
    localbase r0, 2
    mov r0, [r0]
    # mov r0, var[2]
```

### Alternatives

Some instructions could be replaced by alternative way. For example, the following 2 lines are the same meaning.

```asm
    eq LABEL, OP1, OP2
    if OP1 == OP2 goto LABEL
```

Look at the following table for details, and you can use an alternative for more readable in this way.

|       Original        |            Alternative            |
| --------------------- | --------------------------------- |
| `eq LABEL, OP1, OP2`  | `if OP1 == OP2 goto LABEL`        |
| `neq LABEL, OP1, OP2` | `if OP1 != OP2 goto LABEL`        |
| `ge LABEL, OP1, OP2`  | `if OP1 >= OP2 goto LABEL`        |
| `le LABEL, OP1, OP2`  | `if OP1 <= OP2 goto LABEL`        |
| `gt LABEL, OP1, OP2`  | `if OP1 > OP2 goto LABEL`         |
| `lt LABEL, OP1, OP2`  | `if OP1 < OP2 goto LABEL`         |
| `sge LABEL, OP1, OP2` | `if signed OP1 >= OP2 goto LABEL` |
| `sle LABEL, OP1, OP2` | `if signed OP1 <= OP2 goto LABEL` |
| `sgt LABEL, OP1, OP2` | `if signed OP1 > OP2 goto LABEL`  |
| `slt LABEL, OP1, OP2` | `if signed OP1 < OP2 goto LABEL`  |

# license

This product is published under MIT license.
