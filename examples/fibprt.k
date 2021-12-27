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

func fib
    if signed s0 >= 3 goto next
    ret s0
  next:
    sub r0, s0, 2
    call fib
    mov s1, r0
    sub r0, s0, 1
    call fib
    add r0, r0, s1
    ret
