
%PROGRAM
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
    CMPI GR9, 39
    LDI GR2, 1 // load monkey 1 to gr2
    BEQ place
    CMPI GR9, 40
    LDI GR2, 5 // load monkey 2 to gr2
    BEQ place
    CMPI GR9, 41
    LDI GR2, 9 // load monkey 3 to gr2
    BEQ place
    CMPI GR9, 42
    LDI GR2, 13 // load monkey 4 to gr2
    BEQ place
    CMPI GR9, 43
    LDI GR2, 17 // load monkey 5 to gr2
    BEQ place
    LDI GR2, 21 // load monkey 6 to gr2

place:
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

<STANDARD.s>