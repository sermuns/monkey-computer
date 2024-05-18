# Notes for Path.s

## Mandatory registers to save context for: 
    GR0 (holds current baloon)
    GR5 (holds path index) 
    Grx...


## Helpful subrutines:
    Delay : defined in STANDARD.s

## Curret_errors:
    Game_loop is not consistant... For example crashes on 2nd loop currently (fixed) 
    Reason for error: GR5 was manipulated when it shouldnt have been.

## Loop flowchart:
    Game start -> push_balloon_hp -> Loop -> player_dmg or new_balloon
    player_dmg -> dead or new_balloon
    new balloon -> balloon animation 

### Logic within segment
    Game start: Load inital values and update vMem to represent them -> loop

    Push_balloon_hp: Pushes the hp of the balloon ontop of the stack. 

    player_dmg:...

    new_balloon: Indexes path and moves balloon foward with GR
    
## Theoretical flowchart(To compare with actual)

    Game start -> balloon_spawn -> Loop
    Loop -> update screen values and check if its over -> move_balloon(inclusive animation) -> check if balloon is at the end -> monkey_attack(inclusive animation)  -> check if balloon is dead
    
    if dead -> pause game 
    if not -> loop.

    pause game -> let user put new towers -> check for confirm 
    
    if confirm -> loop

## Potential improvements or changes
    Store more information in the heap instead of registers... 