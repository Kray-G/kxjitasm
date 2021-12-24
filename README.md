# Jit Assember

## Background

As long as I see the JIT world, most of JIT assembler is not portable. It means a JIT assember is suited only to a specific platform like x86, x64, arm, or something like that. Therefore, if you use a JIT assember for x64, you can not use it for the other platform. When you want to use it for the arm platform, you have to make it another way and it is very tough activity.

This JIT assembler's purpose is to make it portable. By abstracted assembly language, it makes that you can write it once and use it anywhere. Of course, it has a limitation to suit to various platforms, but by that it will make it more reasonable.

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
* Command
  * A command is mostly defined just corresponding to a function in SLJIT.
* Alternative Representation
  * It would be more readable for the human.
* Comment
  * A comment will be started with `#` and it is continued until the end of line.

### Example

Here is a fibonacci number calculation.

```asm
func entry1
    sge label1, s0, 3
    # if signed s0 >= 3 goto label1
    ret s0
label1:
    sub r0, s0, 2
    call entry1
    mov s1, r0
    sub r0, s0, 1
    call entry1
    add r0, r0, s1
    ret
```

## Mnemonic

### Label and Function Entry Point

The label is started with the label name, and `:` is following the name. See below.

```
labelname:
```

The function entry point is started with `func`, and the entry name will follow that. See the example below for how to write it.

```
func entryname
```

### Instructions

Instructions can be described as below. Some operands will follow the instruction name with separated by comma.

```
instruction operand1, operand2, ...
```

The following table shows the list of mnemonic in this JIT assembler.

| Instruction |    Operands     |                        Meaning                        |
| ----------- | --------------- | ----------------------------------------------------- |
| `jmp`       | LABEL           | Jump to the label.                                    |
| `call`      | ENTRY           | Call a function.                                      |
| `ret`       | -               | Return from a function.                               |
| `mov`       | DST, SRC        | Move SRC to DST.                                      |
| `neg`       | TGT             | Make negative.                                        |
| `clz`       | TGT             | Count a zero bit.                                     |
| `add`       | DST, OP1, OP2   | DST := OP1 + OP2                                      |
| `sub`       | DST, OP1, OP2   | DST := OP1 - OP2                                      |
| `mul`       | DST, OP1, OP2   | DST := OP1 \* OP2                                     |
| `div`       | DST, OP1, OP2   | DST := OP1 / OP2                                      |
| `sdiv`      | DST, OP1, OP2   | DST := OP1 / OP2 (signed)                             |
| `mod`       | DST, OP1, OP2   | DST := OP1 % OP2                                      |
| `smod`      | DST, OP1, OP2   | DST := OP1 % OP2 (signed)                             |
| `shl`       | DST, OP1, OP2   | DST := OP1 \<\< OP2                                   |
| `lshr`      | DST, OP1, OP2   | DST := OP1 \>\> OP2 (logical)                         |
| `ashr`      | DST, OP1, OP2   | DST := OP1 \>\> OP2 (arithmetic)                      |
| `eq`        | LABEL, OP1, OP2 | if OP1 == OP2, jump to LABEL                          |
| `neq`       | LABEL, OP1, OP2 | if OP1 != OP2, jump to LABEL                          |
| `ge`        | LABEL, OP1, OP2 | if OP1 \>= OP2, jump to LABEL                         |
| `le`        | LABEL, OP1, OP2 | if OP1 \<= OP2, jump to LABEL                         |
| `gt`        | LABEL, OP1, OP2 | if OP1 \> OP2, jump to LABEL                          |
| `lt`        | LABEL, OP1, OP2 | if OP1 \< OP2, jump to LABEL                          |
| `sge`       | LABEL, OP1, OP2 | if OP1 \>= OP2, jump to LABEL (comparing with signed) |
| `sle`       | LABEL, OP1, OP2 | if OP1 \<= OP2, jump to LABEL (comparing with signed) |
| `sgt`       | LABEL, OP1, OP2 | if OP1 \> OP2, jump to LABEL (comparing with signed)  |
| `slt`       | LABEL, OP1, OP2 | if OP1 \< OP2, jump to LABEL (comparing with signed)  |

### Alternatives

Some instructions could be replaced by alternative way. Look at the following table, and you can use an alternative for more readable.

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

# Licanse

This product is published under MIT license.
