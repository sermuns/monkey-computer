%PROGRAM 0 1499
start:
    LDI GR2, 2
    STN %HEAP, GR2 // baloon spawn amount
    LDI GR0, 34 //balloon tiletype
    SUBI GR0, 1 //weird fix

push_balloon_hp:
    //hårdkodat (ska öka för varje dödad ballong tex)
    LDI GR6, 4
    PUSH GR6
    
loop:
    STN %VMEM, GR1 // replace tiletype that was overwritten
    // find next path position
    MOV GR6, GR5
    SUBI GR6, 40
    BEQ player_dmg
new_ballon:

    MOV GR3, GR5 // GR3 := GR5
    LDN GR4, %PATH // GR4 := PATH[GR3]
    MOV GR3, GR4 // GR3 := GR4
                        
    LDN GR1, %VMEM // GR1 := VMEM[GR3]
    //STN %VMEM, GR0 // overwrite with balloon
    BRA balloon_animation
check_monke:
    ADDI GR5, 1 // increment path index
    MOV GR4, GR3 //save balloon pos         CHECKAR BARA FÖR APA 1, borde checka 5,9,13 osv (starttillstånd inte animation)

    ADDI GR3, 1 //right neighbour
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation
    //BEQ balloon_dmg

    MOV GR3, GR4 //down
    ADDI GR3, 13
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation

    MOV GR3, GR4 //left
    SUBI GR3, 1
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation

    MOV GR3, GR4 //up
    SUBI GR3, 13
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation

    MOV GR3, GR4
    BRA loop

player_dmg:
    LD GR2, %HEAP
    SUBI GR2, 1
    ST %HEAP, GR2
    SUBI GR2, 0
    BEQ dead

    LDI GR5, 0
    BRA new_ballon

balloon_dmg:
    LDI GR7, 1
    STN %VMEM, GR7
    MOV GR3, GR4
    POP GR6
    SUBI GR6, 1  //different damage for diff monkeys?????
    BEQ balloon_dead
    //otherwise push decreased health
    PUSH GR6
    BRA loop

balloon_dead:
    STN %VMEM, GR1
    LDI GR5, 0
    BRA push_balloon_hp

monke_animation:
    CMPI GR6, 4 //BEHÖVS DELAYS, BYTER ANNARS FÖR SNABBT
    BEQ balloon_dmg
    ADDI GR6, 1
    STN %VMEM, GR6

    LDI GR7, 0x0FFFFF
wait1:
    SUBI GR7, 1
    BNE wait1
    BRA loop 

    BRA monke_animation ;b

reset_anim_state:
    SUBI GR0, 3
    STN %VMEM, GR0

    LDI GR7, 0x0FFFFF
wait2:
    SUBI GR7, 1
    BNE wait2
    BRA loop

    SUBI GR0, 1 ;b
    BRA check_monke
balloon_animation:
    CMPI GR0, 37
    BEQ reset_anim_state
    ADDI GR0, 1
    STN %VMEM, GR0

    LDI GR7, 0x0FFFFF
wait3:
    SUBI GR7, 1
    BNE wait3

    BRA balloon_animation ;b
    


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
1
38
5
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
1
0
1
0
0
0
25
0
9
38
13
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
17
38
21
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
51
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


%HEAP 1700 10 // Health?
