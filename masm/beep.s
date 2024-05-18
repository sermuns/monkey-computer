_pmodreg = GR14
_kbdreg = GR15

%PROGRAM
loop:
    MOV GR0, GR15
    MULI GR0, 100
    MOV GR14, GR0
    BRA loop
end:
    HALT

<STANDARD.s>    