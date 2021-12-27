load lib kxjit
load func jit_test

# Constant Data Store
    @msg "This is a JIT message, successful!\n"

func main
    call jit_test
    mov r0, @msg
    call jit_test
    ret
