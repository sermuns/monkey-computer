%PROGRAM 0 1499
start:
    LDI GR2, 1
    STN %HEAP, GR2 // baloon spawn amount
    LDI GR0, 35 // CONSTANT: balloon tiletype
    
loop:
    STN %VMEM, GR1 // replace tiletype that was overwritten
    // find next path position
    MOV GR6, GR5
    SUBI GR6, 40
    BEQ take_dmg
new_ballon:
    SUBI GR2, 0
    BEQ dead
    MOV GR3, GR5 // GR3 := GR5
    LDN GR4, %PATH // GR4 := PATH[GR3]
    MOV GR3, GR4 // GR3 := GR4
                        
    LDN GR1, %VMEM // GR1 := VMEM[GR3]
    STN %VMEM, GR0 // overwrite with balloon
    ADDI GR5, 1 // increment path index
    BRA loop ;b


take_dmg:
    //TODO SUB players health
    LD GR2, %HEAP
    SUBI GR2, 1
    ST %HEAP, GR2
    LDI GR5, 0
    BRA new_ballon

dead:
BRA dead ;b

%VMEM 1500 130
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
39
38
40
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
38
38
38
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
41
38
42
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
43
38
44
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
38
38
38
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
45
46
47
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
48
49
50

%PATH 1630 40
40
41
31
21
11
12
13
14
15
16
17
18
28
38
37
36
35
34
33
43
53
63
62
61
71
81
82
83
84
85
75
65
55
56
57
67
77
87
88
89

%HEAP 1700 10 // Health?
