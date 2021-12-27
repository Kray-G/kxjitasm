func main
    mov r0, 42
    call fib
    ret

func fib
    if signed s0 >= 3 goto calcfib
    ret s0
  calcfib:
    sub r0, s0, 2
    call fib
    mov s1, r0
    sub r0, s0, 1
    call fib
    add r0, r0, s1
    ret
