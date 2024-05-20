%PROGRAM 0 1499
start:
    LDI GR3, 2
    LDI GR1, 37
main:
    JSR wait_for_break
    CMPI GR15, 1 // A ?
    BEQ drawmem
    BRA main
    
wait_for_break:
    CMPI GR15, 0b11111 // break
    BNE wait_for_break
    RET

drawmem:
    STN %VMEM, GR1
    ADDI GR3, 1
    //LDI GR15, 0
    CMPI GR3, 120
    BEQ changeTile
    BRA main

changeTile:
    LDI GR3, 0
    ADDI GR1, 1
    BRA main

idkhow:
    HALT

%VMEM 1500 420
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
49
63
63
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
51
54
54
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
1
38
5
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
38
38
38
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
9
38
13
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
38
38
38
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
17
38
21
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
38
38
38
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
38
38
38
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
45
50
47

%PATH 1630 69420
52
53
40
27
14
15
16
17
18
19
20
21
34
47
46
45
44
43
42
55
68
81
80
79
92
105
106
107
108
109
96
83
70
71
72
85
98
111
112
113
114


%HEAP 1700 1000 