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
    ADDI GR3, 10
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation

    MOV GR3, GR4 //left
    SUBI GR3, 1
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation

    MOV GR3, GR4 //up
    SUBI GR3, 10
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
    BRA monke_animation ;b

reset_anim_state:
    SUBI GR0, 3
    STN %VMEM, GR0
    SUBI GR0, 1 ;b
    BRA check_monke
balloon_animation:
    CMPI GR0, 37
    BEQ reset_anim_state
    ADDI GR0, 1
    STN %VMEM, GR0
    BRA balloon_animation ;b
    


dead:
BRA dead ;b

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
1
0
1
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

%PATH 1600 40
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
