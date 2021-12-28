load func strtol

# main(int s0, char** s1)
func main
    if s0 != 2 goto end
    mov r0, [s1]
    mov r1, 0
    mov r2, 0
    call strtol
    mov s2, r0
    mov r0, [s1+8]
    mov r1, 0
    mov r2, 0
    call strtol
    add r0, r0, s2
  end:
    ret
