load lib kxjit
load func jit_test

; Constant Data Store
    @msg "This is a JIT message, successful!\n"

; main(int s0, char** s1)
func main
    if s0 == 0 goto end
    mov r0, [s1]
    call jit_test
    mov r0, @msg
    call jit_test
  end:
    ret
