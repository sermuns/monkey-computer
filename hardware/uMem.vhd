LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uMem IS
    PORT (
        address : IN unsigned(7 DOWNTO 0);
        data : OUT STD_LOGIC_VECTOR(24 DOWNTO 0));
END uMem;

ARCHITECTURE func OF uMem IS
    TYPE u_mem_t IS ARRAY(natural range<>) OF STD_LOGIC_VECTOR(24 DOWNTO 0);
    CONSTANT u_mem_array : u_mem_t := (
        -- 000_000_0000_0_00_0000_00000000
        -- TB _FB _ALU_ P_S_ SEQ _uADR

        -- HAMTNING
        b"010_000_0000_0_00_0000_00000000",--[ 0|00000000] ASR := PC
        b"001_100_0000_1_00_0000_00000000",--[ 1|00000001] IR := PM, PC++
        b"000_000_0000_0_00_0010_00000000",--[ 2|00000010] uPC := K2

        -- ADDRESSERING
        b"100_000_0000_0_00_0001_00000000",--[ 3|00000011] {DIREKT}    ASR := IR, uPC := K1
        b"010_000_0000_1_00_0001_00000000",--[ 4|00000100] {OMEDELBAR} ASR := PC, PC++, uPC:= K1
        b"100_000_0000_0_00_0000_00000000",--[ 5|00000101] ASR := IR
        b"001_000_0000_0_00_0001_00000000",--[ 6|00000110] {INDIREKT}  ASR:= PM, uPC:= K1
        b"100_011_0100_0_00_0000_00000000",--[ 7|00000111] {INDEXERAD} AR := IR
        b"101_011_0011_0_00_0000_00000000",--[ 8|00001000] AR += GR3 (GR3 styrs av M)
        b"011_000_0000_0_00_0001_00000000",--[ 9|00001001] ASR := AR, uPC := K1

        -- EXEKVERING
        b"001_101_0000_0_00_0011_00000000",--[10|00001010] {LOAD} GRx := PM
        b"101_001_0000_0_00_0011_00000000",--[11|00001011] {STORE} PM := GRx
        b"101_011_0100_0_00_0000_00000000",--[12|00001100] {ADD} AR := GRx
        b"001_011_0001_0_00_0000_00000000",--[13|00001101] AR += PM
        b"011_101_0000_0_00_0011_00000000",--[14|00001110] GRx := AR
        b"101_011_0100_0_00_0000_00000000",--[15|00001111] {SUB} AR := GRx
        b"001_011_0010_0_00_0000_00000000",--[16|00010000] AR := GRx - PM
        b"011_101_0000_0_00_0011_00000000",--[17|00010001] GRx := AR
        b"101_011_0000_0_00_0000_00000000",--[18|00010010] {CMP} AR := GRx
        b"001_011_1001_0_00_0000_00000000",--[19|00010011] AR := GRx AND PM
        b"011_101_0000_0_00_0011_00000000",--[20|00010100] GRx := AR
        b"101_011_0100_0_00_0000_00000000",--[21|00010101] {AND} AR := GRx
        b"001_011_0101_0_00_0000_00000000",--[22|00010110] AR := GRx AND PM
        b"011_101_0000_0_00_0011_00000000",--[23|00010111] GRx := AR
        b"101_011_0000_0_00_0000_00000000",--[24|00011000] {LSR} AR := GRx
        b"001_011_0111_0_00_0000_00000000",--[25|00011001] AR := GRx >> PM
        b"101_011_0000_0_00_0000_00000000",--[26|00011010] {MUL} AR := GRx
        b"001_011_0011_0_00_0000_00000000",--[27|00011011] AR := GRx * PM 
        b"011_101_0000_0_00_0011_00000000",--[28|00011100] GRx := AR
        b"101_011_0100_0_00_0000_00000000",--[29|00011101] {OR} AR := GRx
        b"001_011_0110_0_00_0000_00000000",--[30|00011110] AR := GRx OR PM
        b"011_101_0000_0_00_0011_00000000",--[31|00011111] GRx := AR
        b"010_011_0100_0_00_0000_00000000",--[32|00100000] {BRA} AR := PC
        b"100_011_0001_0_00_0000_00000000",--[33|00100001] AR += IR
        b"011_010_0000_0_00_0011_00000000",--[34|00100010] PC := AR + 1
        b"000_000_0000_0_00_0100_00100000",--[35|00100011] {BNE} if Z=0 jump to BRA   TODO: figure out status flags
        b"000_000_0000_0_00_0011_00000000",--[36|00100100] uPC = 0, PC++
        b"000_000_0000_0_00_0110_00100000",--[37|00100101] {BEQ} if Z=1 jump to BRA   TODO: figure out status flags
        b"000_000_0000_0_00_0011_00000000",--[38|00100110] uPC := 0, PC++
        b"110_000_0000_0_00_0000_00000000",--[39|00100111] {JSR} ASR := SP,
        b"010_001_0000_0_01_0000_00000000",--[40|00101000] PM(ASR) := PC, sp-- 
        b"110_000_0000_0_00_0101_00100000",--[41|00101001] ASR uPC = BRA
        b"110_000_0000_0_00_0000_00000000",--[42|00101010] {PUSH} ASR:=SP, 
        b"101_001_0000_0_01_0011_00000000",--[43|00101011] PM(ASR) := GRx, sp--
        b"000_000_0000_0_10_0000_00000000",--[44|00101100] {POP} SP++
        b"110_000_0000_0_00_0000_00000000",--[45|00101101] ASR:=SP, 
        b"001_101_0000_0_00_0011_00000000",--[46|00101110] GRx := PM(ASR),
        b"110_000_0000_0_00_0000_00000000",--[47|00101111] {RET} PM(ASR) := PC,
        b"001_010_0000_0_10_0011_00000000",--[48|00110000] PC = PM(SP), sp++, uPC = 0
        b"111_111_0000_0_00_1111_00000000" --[49|00110001] {HALT}
    );
BEGIN
    data <= u_mem_array(TO_INTEGER(address));
END ARCHITECTURE;
