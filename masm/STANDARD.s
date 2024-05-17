delay:
    PUSH GR0
    LDI GR0, 0x01
delay_loop:
    SUBI GR0, 1
    BNE delay_loop
delay_end:
    POP GR0
    RET

wait_for_player_input:
    CMPI GR15, 3     // loop until user input
    BNE wait_for_player_input
    LDI GR15, 0
    RET

left_input:
    LDI GR0, 1
    RET

right_input:

    LDI GR0, 2
    RET

up_input:
    LDI GR0, 3
    RET

down_input:
    LDI GR0, 4
    RET

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
1
0
1
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
53
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
64
64
64
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
38
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