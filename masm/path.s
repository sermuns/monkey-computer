_playerhpdigit1 = %HEAP+1 
_playerhpdigit2 = %HEAP+2
_playergolddigit1 = %HEAP+3
_playergolddigit2 = %HEAP+4
_currentround = %HEAP+5

%PROGRAM 0 69 
start:
    JSR wait_for_player_input
    LDI GR2, 1
    ST _currentround, GR2

    // update screen 
    LDI GR2, 8
    ST _playerhpdigit1, GR2 // hp
    LDI GR2, 0
    ST _playerhpdigit2, GR2 // hp
    LDI GR2, 4
    ST _playergolddigit1, GR2 // gold
    ST _playergolddigit2, GR2 // gold
    JSR update_gold
    JSR update_hp

    //load inital balloon
    LDI GR0, 34 //balloon tiletype
    SUBI GR0, 1 //weird fix

push_balloon_hp:
    //* loads the current round and indexes in the round scaling to get correct hp
    LD GR6, _currentround 
    ADDI GR6, 2
    PUSH GR6
    
loop:
    STN %VMEM, GR1 // replace tiletype that was overwritten
    // find next path position
    MOV GR6, GR5
    SUBI GR6, 40 // 40 is the end of the map! taken from path index. 
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
    LD GR2, _playerhpdigit1
    SUBI GR2, 1
    ST _playerhpdigit1, GR2
    JSR update_hp

    SUBI GR2, 0
    BEQ dead

    LDI GR5, 0
    BRA new_ballon
// 
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

//* If the balloon is dead, increase the round and update the gold. then push new baloon /
balloon_dead:
    PUSH GR3

    STN %VMEM, GR1
    LDI GR5, 0

    //* get gold dependent on enemy hp
    
    LD GR7, _playergolddigit1
    ADD GR7, _currentround
    ST _playergolddigit1, GR7
    JSR update_gold

    // * round increase it and store it
    ADDI GR3, 1
    ST _currentround, GR3

    POP GR3
    BRA push_balloon_hp

//* Same as baloon animation but for the monkey. /
monke_animation:
    CMPI GR6, 4
    BEQ balloon_dmg
    ADDI GR6, 1
    STN %VMEM, GR6

    JSR delay

    BRA monke_animation ;b

//* Goes back 3 frames for tiletype/
reset_anim_state:
    SUBI GR0, 3
    STN %VMEM, GR0

    JSR delay

    SUBI GR0, 1 ;b
    BRA check_monke

//*hardcoded to work for specefic baloon that is being animated by looping through its frames/
balloon_animation:
    CMPI GR0, 37
    BEQ reset_anim_state
    ADDI GR0, 1
    STN %VMEM, GR0

    JSR delay

    BRA balloon_animation ;b


dead:
BRA dead ;b

//* Waits for player input which is saved in GR15. /
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

    LDI GR15, 0
    RET

//* Loads HP into GR2 and updates the value on screen. /
update_hp:
    PUSH GR2

    LD GR2, _playerhpdigit1
    ADDI GR2, 54 
    ST %VMEM+12, GR2
    LD GR2, _playerhpdigit2
    ADDI GR2, 54
    ST %VMEM+11, GR2

    POP GR2
    RET

//* Loads gold into GR2 and updates the value on screen. /
update_gold:
    PUSH GR2

    LD GR2, _playergolddigit1
    ADDI GR2, 54
    ST %VMEM+25, GR2
    LD GR2, _playergolddigit2
    ADDI GR2, 54
    ST %VMEM+24, GR2

    POP GR2
    RET


<STANDARD.s>
