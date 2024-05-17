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
    CMPI GR6, 4
    BEQ balloon_dmg
    ADDI GR6, 1
    STN %VMEM, GR6

    LDI GR7, 0x0FFFFF
wait1:
    SUBI GR7, 1
    BNE wait1

    BRA monke_animation ;b

reset_anim_state:
    SUBI GR0, 3
    STN %VMEM, GR0

    LDI GR7, 0x0FFFFF
wait2:
    SUBI GR7, 1
    BNE wait2

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

read_input:
    CMPI GR15, 1
    BEQ left_input // A key
    CMPI GR15, 2
    BEQ right_input // D key
    CMPI GR15, 4 // W key
    BEQ up_input
    CMPI GR15, 8 // S key
    BEQ down_input
    CMPI GR15, 3 
    RET

mark_input_as_read:
    LDI GR15, 0
    RET

update_hp:
    LDI GR0, 54
    LDI GR1, 11
    LDI GR3, 4
    STN %VMEM, GR1 
    STN %VMEM, GR1
    RET

wait_for_player_input:
   CMPI GR15, 3     // loop until user input
    BNE wait_for_player_input

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


%HEAP 1700 10 
