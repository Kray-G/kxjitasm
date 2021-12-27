load lib kxjit
load func jit_test
data @msg "This is a JIT message, successful!\n"

func main
    mov r0, 0
    call jit_test
    mov r0, @msg
    call jit_test
    ret
