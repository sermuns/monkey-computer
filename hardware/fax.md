# Mikro
## TB och FB
000  ASR  
001  PM   
010  PC   
011  AR/ALU
100  IR   
101  GRx 
110  SP 
111  nop do nothing!!
## ALU_op
0000  NOP 
0001  ADD   AR += bus
0010  SUB   AR -= bus
0011  MUL   AR *= bus
0100  LOAD  AR := bus
0101  AND   AR &= bus
0110  OR    AR |= bus
0111  LSR   AR := (AR >> bus)
1000  LSL   AR := (AR << bus)
1001  CMP   AR - bus (only set flags)
## P
0 ...
1 = PC++
## SEQ
0000  uPC++
0001  uPC := K1
0010  uPC := K2
0011  uPC := 0
0100  IF Z=0 uPC := uADR
0101  uPC := uADR (BRA)
0110  IF Z=1 uPC := uADR
0111  IF N=1 uPC := uADR
1000  IF C=1 uPC := uADR
1001  IF C=0 uPC := uADR
1111  uADR := uADR
## Stack pekare
00 SP = SP
10 SP++
01 SP--


# Assembly 
## OP-koder
00000 LD
00001 ST  
00010 ADD
00011 SUB
00100 CMP
00101 AND
00110 OR
00111 LSR
01000 LSL
01001 JSR
01010 BRA
01011 BNE
01100 BEQ
01101 PUSH
01110 POP
01111 MUL
10000 RET
10001 SWAP
10010 MOV
11111 HALT

## OP-Notes
Swap is destructive against AR...

## Moder (M)
00 Direkt
01 Omedelbar (Immediate)
10 Indirekt
11 Indexerad
...


# Video
VGA-display
Resolution: 640x480
25MHz klocka

Skärmen delas upp i:
10x10 kvadratiska tiles, 

12x12 logiska pixlar per tile
eller
48x48 subpixlar per tile

**Tiles:** totalt 64 st
0: gräs
1-4: apa 1 frame 1-4
5-8: apa 2 frame 1-4
9-12: apa 3 frame 1-4
13-16: apa 4 frame 1-4
17-20: apa 5 frame 1-4
21-24: apa 6 frame 1-4
25: väg
26-29: ballon 1 frame 1-4 BLÅ
30-33: ballon 2 frame 1-4 TURKÅS tuqoiseeeeeeeeeeeeeee
34-37: ballon 3 frame 1-4 ORANGE
38: svart
39: apa 1 highlighted
40: apa 2 highlighted
41: apa 3 highlighted
42: apa 4 highlighted
43: apa 5 highlighted
44: apa 6 highlighted
45: R
46: R highlighted
47: Q
48: Q highlighted
49: HP 
50: C 
51: G
52: C highlighted
53: Cursor
54-63: Numbers 0-9
64: NOTHING ATM
65: gräs highlighted
66: väg highlighted

