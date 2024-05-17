_playerhp = %HEAP+1
_playergold = %HEAP+2


%PROGRAM 0 69 
start:
    JSR wait_for_player_input
    LDI GR2, 8
    ST _playerhp, GR2 // hp
    LDI GR2, 100
    ST _playergold, GR2 // gold
    JSR update_hp
    LDI GR0, 34 //balloon tiletype
    SUBI GR0, 1 //weird fix

push_balloon_hp:
    //hårdkodat (ska öka för varje dödad ballong tex)
    LDI GR6, 5
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
    LD GR2, _playerhp
    SUBI GR2, 1
    ST _playerhp, GR2
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

    JSR delay

    BRA monke_animation ;b

reset_anim_state:
    SUBI GR0, 3
    STN %VMEM, GR0

    JSR delay

    SUBI GR0, 1 ;b
    BRA check_monke
balloon_animation:
    CMPI GR0, 37
    BEQ reset_anim_state
    ADDI GR0, 1
    STN %VMEM, GR0

    JSR delay

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
    LD GR2, _playerhp //
    ADDI GR2, 54 
    ST %VMEM+12, GR2
    RET



<STANDARD.s>