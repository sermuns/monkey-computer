delay:
    PUSH GR0
    LDI GR0, 0x02
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
    
set_highlighted_grass:
    LDI GR2, 65
    STN %VMEM, GR2
    BRA read_input_end

set_highlighted_path:
    LDI GR2, 66
    STN %VMEM, GR2
    BRA read_input_end

set_highlighted_continue:
    LDI GR2, 52
    STN %VMEM, GR2
    BRA read_input_end

set_highlighted_black:
    LDI GR2, 53
    STN %VMEM, GR2
    BRA read_input_end

set_highlighted_reset:
    LDI GR2, 46
    STN %VMEM, GR2
    BRA read_input_end

set_highlighted_quit:
    LDI GR2, 48
    STN %VMEM, GR2
    BRA read_input_end

set_highlighted_monkey1:
    LDI GR2, 39
    STN %VMEM, GR2
    BRA read_input_end
set_highlighted_monkey2:
    LDI GR2, 40
    STN %VMEM, GR2
    BRA read_input_end
set_highlighted_monkey3:
    LDI GR2, 41
    STN %VMEM, GR2
    BRA read_input_end
set_highlighted_monkey4:
    LDI GR2, 42
    STN %VMEM, GR2
    BRA read_input_end
set_highlighted_monkey5:
    LDI GR2, 43
    STN %VMEM, GR2
    BRA read_input_end
set_highlighted_monkey6:
    LDI GR2, 44
    STN %VMEM, GR2
    BRA read_input_end

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