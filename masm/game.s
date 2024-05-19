%PROGRAM
start:
    LDI GR10, 0 // which anim frame?
main_loop:
    JSR next_anim
    ADDI GR10, 1 // next anim frame
    BRA loop

dead:
    HALT


// --- subroutines below ----
next_anim:
    PUSH GR0
    LDI GR0, 129 // vmem size
next_anim_loop:
    SUBI GR0, 1
    SUBI GR0, 1
    MOV GR3, GR0
    STN %VMEM, GR10
    BNE next_anim_loop

<STANDARD.s>
