%PROGRAM
start:
    LDI GR0, 10
    LDI GR3, 10
loop:
    STN %VMEM, GR0
    SUBI GR3, 1
    BNE loop ;b
end:
    HALT

<STANDARD.s>