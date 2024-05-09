%PROGRAM 0 1499
start:
    LDI GR0, 35 // balloon tiletype
    LDI GR1, 0 // overwritten tiletype
    LDI GR3, 9 // index into vmem
loop:
    STN %VMEM, GR1 // replace tiletype that was overwritten
    ADDI GR3, 1 // x++
    LDN GR1, %VMEM // load the tiletype being overwritten
    STN %VMEM, GR0 // overwrite with balloon
    BRA loop ;b


%VMEM 1500 100
0
0
0
0
0
0
0
0
0
0
0
25
25
25
25
25
25
25
25
0
0
25
0
0
0
0
0
0
25
0
0
25
0
25
25
25
25
25
25
0
25
25
0
25
0
0
0
0
0
0
0
0
0
25
0
25
25
25
0
0
0
25
25
25
0
25
0
25
0
0
0
25
0
0
0
25
0
25
0
0
0
25
25
25
25
25
0
25
25
25
0
0
0
0
0
0
0
0
0
0

%PATH 1600 100



%HEAP 1700 100
