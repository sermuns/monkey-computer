%PROGRAM 0
main:
    LDI GR0, 5
    LDI GR3, 10, GR0
loop:
    STN %VMEM, GR0
    JSR delay
    SUBI GR3, 1
    BNE loop
    HALT

delay:
    LDI GR2, 0xFFFFFF
loop2:
    SUBI GR2, 1
    BNE loop2
    RET

<STANDARD.s>