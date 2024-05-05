LDI GR0, 1 --Loading different tiles into REGISTERS
LDI GR1, 2
LDI GR2, 3
LDI GR3, 4
LDI GR4, 5
LDI GR5, 6
LDI GR6, 7

LDI GR7, 9
PUSH GR7

ST 1500, GR1
ST 1501, GR2
ST 1502, GR3
ST 1503, GR4
ST 1504, GR5
ST 1505, GR6
@ RET --Check implementation sp might need to increment before last step. Should send us to  row 10


