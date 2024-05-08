%PROGRAM 0 1499
main:
BRA baloon_spawn
baloon_spawn:
LDI GR0, 12 -- load literal baloon 12
ST %HEAP, GR0 --Store in heap
BRA move_balloon
move_balloon:
LD GR0, %HEAP --Load from heap
ST %VMEM, GR0 --Store in video memory
LSR GR0, 4 --Shift right 4 bits to move x position

loop:
BRA loop

%VMEM 1500 25
0b000000_000000_000000_000000
0b000000_000000_000000_000000
0b000000_000000_000000_011001
0b011001_011001_011001_011001
0b011001_011001_011001_000000
0b000000_011001_000000_000000
0b000000_000000_000000_000000
0b011001_000000_000000_011001
0b000000_011001_011001_011001
0b011001_011001_011001_000000
0b011001_011001_000000_011001
0b000000_000000_000000_000000
0b000000_000000_000000_000000
0b000000_011001_000000_011001
0b011001_011001_000000_000000
0b000000_011001_011001_011001
0b000000_011001_000000_011001
0b000000_000000_000000_011001
0b000000_000000_000000_011001
0b000000_011001_000000_000000
0b000000_011001_011001_011001
0b011001_011001_000000_011001
0b011001_011001_000000_000000
0b000000_000000_000000_000000
0b000000_000000_000000_000000

%HEAP 1500 100
0b000000_000000_000000_000000
0b000000_000000_000000_000000