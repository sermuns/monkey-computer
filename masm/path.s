_playerhpdigit1 = %HEAP+1 
_playerhpdigit2 = %HEAP+2
_playergolddigit1 = %HEAP+3
_playergolddigit2 = %HEAP+4
_currentround = %HEAP+5
_cursorpos = %HEAP+6
_cursortile = %HEAP+7

%PROGRAM 0 69 
start:
    JSR wait_for_player_input
    LDI GR2, 1
    ST _currentround, GR2

    // update screen 
    LDI GR2, 1
    ST _playerhpdigit1, GR2 // hp
    LDI GR2, 1
    ST _playerhpdigit2, GR2 // hp
    LDI GR2, 3
    ST _playergolddigit1, GR2 // gold
    LDI GR2, 0
    ST _playergolddigit2, GR2 // gold
    JSR update_gold
    JSR update_hp

    //load inital balloon
    LDI GR0, 34 //balloon tiletype
    SUBI GR0, 1 //weird fix


push_balloon_hp:
    //* loads the current round and adds it to the balloon round + 1. /
    LD GR6, _currentround 
    ADDI GR6, 1
    PUSH GR6
    
reset_cursor:
    LDI GR2, 0
    ST _cursortile, GR2 // save tile that cursor replaces
    LDI GR2, 56
    ST _cursorpos, GR2 // put cursor in start pos
    LDI GR2, 65
    ST %VMEM+56, GR2 // update screen, ersätt 56 med cursorpos
    
shopping_phase:
    JSR read_input
    // should return with GR7 being 0 or 1
    CMPI GR8, 1
    LDI GR8, 0
    BNE shopping_phase // continue shopping

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
    CMPI GR6, 5
    BEQ monke_animation
    CMPI GR6, 9
    BEQ monke_animation
    CMPI GR6, 13
    BEQ monke_animation
    CMPI GR6, 17
    BEQ monke_animation
    CMPI GR6, 21
    BEQ monke_animation


    MOV GR3, GR4 //down
    ADDI GR3, 13
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation
    CMPI GR6, 5
    BEQ monke_animation
    CMPI GR6, 9
    BEQ monke_animation
    CMPI GR6, 13
    BEQ monke_animation
    CMPI GR6, 17
    BEQ monke_animation
    CMPI GR6, 21
    BEQ monke_animation

    MOV GR3, GR4 //left
    SUBI GR3, 1
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation
    CMPI GR6, 5
    BEQ monke_animation
    CMPI GR6, 9
    BEQ monke_animation
    CMPI GR6, 13
    BEQ monke_animation
    CMPI GR6, 17
    BEQ monke_animation
    CMPI GR6, 21
    BEQ monke_animation

    MOV GR3, GR4 //up
    SUBI GR3, 13
    LDN GR6, %VMEM
    CMPI GR6, 1
    BEQ monke_animation
    CMPI GR6, 5
    BEQ monke_animation
    CMPI GR6, 9
    BEQ monke_animation
    CMPI GR6, 13
    BEQ monke_animation
    CMPI GR6, 17
    BEQ monke_animation
    CMPI GR6, 21
    BEQ monke_animation

    MOV GR3, GR4
    BRA loop

player_dmg:
    LD GR2, _playerhpdigit1
    CMPI GR2, 0
    BEQ decrement_of_hp
    SUBI GR2, 1
    ST _playerhpdigit1, GR2
player_dmg_2:
    JSR update_hp
    LD GR2, _playerhpdigit1
    ADD GR2, _playerhpdigit2
    BEQ dead

    LDI GR5, 0
    BRA new_ballon
    
balloon_dmg:
    SUBI GR6, 3
    STN %VMEM, GR6
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
    ADDI GR7, 1 // current gold reward.
    CMPI GR7, 10
    BEQ increment_of_gold
    ST _playergolddigit1, GR7
balloon_dead2:
    JSR update_gold
    // * round increase it and store it
    LD GR3, _currentround
    ADDI GR3, 1
    ST _currentround, GR3
    POP GR3
    
    BRA push_balloon_hp


//* Same as baloon animation but for the monkey. /
monke_animation:
    CMPI GR6, 4
    BEQ balloon_dmg
    CMPI GR6, 8
    BEQ balloon_dmg
    CMPI GR6, 12
    BEQ balloon_dmg
    CMPI GR6, 16
    BEQ balloon_dmg
    CMPI GR6, 20
    BEQ balloon_dmg
    CMPI GR6, 24
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
    ADDI GR0, 1
    CMPI GR0, 29
    BEQ reset_anim_state
    CMPI GR0, 33
    BEQ reset_anim_state
    CMPI GR0, 37
    BEQ reset_anim_state
    STN %VMEM, GR0

    JSR delay

    BRA balloon_animation ;b


dead:
    HALT

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
    CMPI GR15, 3 // Space
    BEQ confirm_input_pick
    CMPI GR15, 5 // Enter key
    BEQ continue_game
read_input_end:
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

left_input:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move left
    SUBI GR3, 1
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos

    LD GR2, _cursortile
    CMPI GR2, 0
    BEQ set_highlighted_grass
    CMPI GR2, 1
    BEQ set_highlighted_monkey1
    CMPI GR2, 5
    BEQ set_highlighted_monkey2
    CMPI GR2, 9
    BEQ set_highlighted_monkey3
    CMPI GR2, 13
    BEQ set_highlighted_monkey4
    CMPI GR2, 17
    BEQ set_highlighted_monkey5
    CMPI GR2, 21
    BEQ set_highlighted_monkey6
    CMPI GR2, 25
    BEQ set_highlighted_path
    CMPI GR2, 38
    BEQ set_highlighted_black
    CMPI GR2, 45
    BEQ set_highlighted_reset
    CMPI GR2, 47
    BEQ set_highlighted_quit
    CMPI GR2, 50
    BEQ set_highlighted_continue
    // If no highlighted texture get standard cursor
    LDI GR2, 53
    STN %VMEM,GR2
    BRA read_input_end

right_input:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move right
    ADDI GR3, 1
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos

    LD GR2, _cursortile
    CMPI GR2, 0
    BEQ set_highlighted_grass
    CMPI GR2, 1
    BEQ set_highlighted_monkey1
    CMPI GR2, 5
    BEQ set_highlighted_monkey2
    CMPI GR2, 9
    BEQ set_highlighted_monkey3
    CMPI GR2, 13
    BEQ set_highlighted_monkey4
    CMPI GR2, 17
    BEQ set_highlighted_monkey5
    CMPI GR2, 21
    BEQ set_highlighted_monkey6
    CMPI GR2, 25
    BEQ set_highlighted_path
    CMPI GR2, 38
    BEQ set_highlighted_black
    CMPI GR2, 45
    BEQ set_highlighted_reset
    CMPI GR2, 47
    BEQ set_highlighted_quit
    CMPI GR2, 50
    BEQ set_highlighted_continue
    // If no highlighted texture get standard cursor
    LDI GR2, 53
    STN %VMEM,GR2
    BRA read_input_end

up_input:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move up
    SUBI GR3, 13
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos

    LD GR2, _cursortile
    CMPI GR2, 0
    BEQ set_highlighted_grass
    CMPI GR2, 1
    BEQ set_highlighted_monkey1
    CMPI GR2, 5
    BEQ set_highlighted_monkey2
    CMPI GR2, 9
    BEQ set_highlighted_monkey3
    CMPI GR2, 13
    BEQ set_highlighted_monkey4
    CMPI GR2, 17
    BEQ set_highlighted_monkey5
    CMPI GR2, 21
    BEQ set_highlighted_monkey6
    CMPI GR2, 25
    BEQ set_highlighted_path
    CMPI GR2, 38
    BEQ set_highlighted_black
    CMPI GR2, 45
    BEQ set_highlighted_reset
    CMPI GR2, 47
    BEQ set_highlighted_quit
    CMPI GR2, 50
    BEQ set_highlighted_continue
    // If no highlighted texture get standard cursor
    LDI GR2, 53
    STN %VMEM,GR2
    BRA read_input_end

down_input:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move down
    ADDI GR3, 13
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos
    // change to highlighted
    LD GR2, _cursortile
    CMPI GR2, 0
    BEQ set_highlighted_grass
    CMPI GR2, 1
    BEQ set_highlighted_monkey1
    CMPI GR2, 5
    BEQ set_highlighted_monkey2
    CMPI GR2, 9
    BEQ set_highlighted_monkey3
    CMPI GR2, 13
    BEQ set_highlighted_monkey4
    CMPI GR2, 17
    BEQ set_highlighted_monkey5
    CMPI GR2, 21
    BEQ set_highlighted_monkey6
    CMPI GR2, 25
    BEQ set_highlighted_path
    CMPI GR2, 38
    BEQ set_highlighted_black
    CMPI GR2, 45
    BEQ set_highlighted_reset
    CMPI GR2, 47
    BEQ set_highlighted_quit
    CMPI GR2, 50
    BEQ set_highlighted_continue
    // If no highlighted texture get standard cursor
    LDI GR2, 53
    STN %VMEM,GR2
    BRA read_input_end

confirm_input_pick:
    LDI GR15, 0 // reset key input
    // if we donw have any money move out
    LD GR10, _playergolddigit1
    ADD GR10, _playergolddigit2
    BEQ read_input_end
    //Check if already picked monkey
    LD GR2, _cursortile
    CMPI GR2, 1
    LDI GR9, 39
    BEQ confirm_input_place
    CMPI GR2, 5
    LDI GR9, 40
    BEQ confirm_input_place
    CMPI GR2, 9
    LDI GR9, 41
    BEQ confirm_input_place
    CMPI GR2, 13
    LDI GR9, 42
    BEQ confirm_input_place
    CMPI GR2, 17
    LDI GR9, 43
    BEQ confirm_input_place
    CMPI GR2, 21
    LDI GR9, 44
    BEQ confirm_input_place
    // If no mokey is being hovered reset GR9 to 0
    LDI GR9, 0
    // check if we should do something not regarding monkeys
    CMPI GR2, 45 // reset
    BEQ dead
    CMPI GR2, 47 // quit
    BEQ dead
    CMPI GR2, 50 // continue
    BEQ continue_game
   
    BRA read_input_end

confirm_input_place:
    CMPI GR15, 3 // Space
    BEQ place_check
    CMPI GR15, 4 // W
    BEQ place_up
    CMPI GR15, 1 // A
    BEQ place_left
    CMPI GR15, 2 // S
    BEQ place_right
    CMPI GR15, 8 // D
    BEQ place_down
    BRA confirm_input_place // Check again

place_check:
    // GR9 is updated in confirm_input_pick
    LD GR3, _cursorpos
    LD GR2, _cursortile
    CMPI GR2, 0
    BNE confirm_input_place // if not being placed on grass keep checking for inputs
    // check which monkey to place
    // load monkey 1 to gr2
    CMPI GR9, 39
    LDI GR2, 1
    BEQ purchase
    // load monkey 2 to gr2
    CMPI GR9, 40
    LDI GR2, 5
    BEQ purchase
    // load monkey 3 to gr2
    CMPI GR9, 41
    LDI GR2, 9 
    BEQ purchase
    // load monkey 4 to gr2
    CMPI GR9, 42
    LDI GR2, 13
    BEQ purchase
    // load monkey 5 to gr2
    CMPI GR9, 43
    LDI GR2, 17 
    BEQ purchase
    // load monkey 6 to gr2
    LDI GR2, 21 

purchase:
    // decrease money
    LD GR10, _playergolddigit1
    CMPI GR10, 0
    BEQ decrement_of_gold
    SUBI GR10, 1
    ST _playergolddigit1, GR10

place:
    // update gold 
    JSR update_gold
    // place correct monkey(gr2)
    ST _cursortile, GR2
    STN %VMEM, GR2
    LDI GR15, 0
    BRA read_input_end

place_up:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move up
    SUBI GR3, 13
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos

    STN %VMEM, GR9
    LDI GR15, 0
    BRA confirm_input_place
    
place_left:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move right
    SUBI GR3, 1
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos

    STN %VMEM, GR9
    LDI GR15, 0
    BRA confirm_input_place

place_right:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move right
    ADDI GR3, 1
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos

    STN %VMEM, GR9
    LDI GR15, 0
    BRA confirm_input_place

place_down:
    // replace current cursor to original tile
    LD GR2, _cursortile
    LD GR3, _cursorpos
    STN %VMEM,GR2
    // move down
    ADDI GR3, 13
    ST _cursorpos, GR3
    // GR2 => _cursortile
    LDN GR2, %VMEM
    ST _cursortile, GR2

    LD GR3, _cursorpos

    STN %VMEM, GR9
    LDI GR15, 0
    BRA confirm_input_place

continue_game:
    LDI GR8,1
    BRA read_input_end

increment_of_gold:
    LDI GR7, 0
    ST _playergolddigit1, GR7
    LD GR7, _playergolddigit2
    ADDI GR7, 1
    ST _playergolddigit2, GR7
    BRA balloon_dead2

decrement_of_gold:
    LD GR7, _playergolddigit2
    CMPI GR7, 0
    BEQ confirm_input_place
    LDI GR10, 9
    ST _playergolddigit1, GR10
    LD GR10, _playergolddigit2
    SUBI GR10, 1
    ST _playergolddigit2, GR10
    BRA place

decrement_of_hp:
    LD GR7, _playerhpdigit2
    CMPI GR7, 0
    BEQ player_dmg_2
    LDI GR2, 9
    ST _playerhpdigit1, GR2
    LD GR2, _playerhpdigit2
    SUBI GR2, 1
    ST _playerhpdigit2, GR2
    BRA player_dmg_2

<STANDARD.s>
