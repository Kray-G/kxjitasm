load func printf

# Constant Data Store
    @fmt   "var(%2lld) = %4lld\n"

func main
    mov var[10], 0  # Reserved 10 vars.

    # Setup variables, var[i] = i * 100
    mov s0, 0
    goto loop1
  next1:
    localbase r3, s0
    mov r0, s0
    mul r0, r0, 100
    mov [r3], r0
    add s0, s0, 1
  loop1:
    if signed s0 <= 10 goto next1

    # Display variables, with counting down the index from 10 to 0.
    mov s0, 10
    goto loop2
  next2:
    localbase r3, s0
    mov r2, [r3]
    mov r1, s0
    mov r0, @fmt
    call printf
    sub s0, s0, 1
  loop2:
    if signed 0 <= s0 goto next2

    ret
