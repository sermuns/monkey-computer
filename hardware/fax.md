# Mikro
## TB och FB
000  ASR  
001  PM   
010  PC   
011  AR (ALU)
100  IR   
101  GRx  
111  nop do nothing!!
## ALU
0000  NOP 
0001  ADD   R := A + B
0010  SUB   R := A - B
0011  MUL   R := A * B
0100  LOAD  R := B
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

## K1 Values
OP    -> u-adress
00000 -> 01010 (LOAD)
00001 -> 01011 (STORE)
00010 -> 01100 (ADD)
00011 -> 01111 (SUB)
00100 -> 10010 (CMP)
00101 -> 10101 (AND)
01111 -> 11000 (MUL)
11111 -> 10011 (HALT)  TODO change halt value

# Assembly 
## OP-koder
00000 LD
00001 ST  
00010 ADD
00011 SUB
11111 HALT

## Moder (M)
00 Direkt
01 Omedelbar (Immediate)
10 Indirekt
11 Indexerad
...

