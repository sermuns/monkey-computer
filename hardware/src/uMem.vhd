LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uMem IS
    PORT (
        address : IN unsigned(7 DOWNTO 0);
        data : OUT STD_LOGIC_VECTOR(22 DOWNTO 0));
END uMem;

ARCHITECTURE func OF uMem IS
    TYPE u_mem_t IS ARRAY(0 TO 255) OF STD_LOGIC_VECTOR(22 DOWNTO 0);
    CONSTANT u_mem_array : u_mem_t := (
        -- 000_000_0000_0_0000_00000000
        -- TB _FB _ALU _P_SEQ _uADR

        -- HAMTNING
        STD_LOGIC_VECTOR'(b"010_000_0000_0_0000_00000000"), --[ 0|00000000] ASR := PC
        STD_LOGIC_VECTOR'(b"001_100_0000_1_0000_00000000"), --[ 1|00000001] IR := PM, PC++
        STD_LOGIC_VECTOR'(b"000_000_0000_0_0010_00000000"), --[ 2|00000010] uPC := K2

        -- ADDRESSERING
        STD_LOGIC_VECTOR'(b"100_000_0000_0_0001_00000000"), --[ 3|00000011] {DIREKT}    ASR := IR, uPC := K1
        STD_LOGIC_VECTOR'(b"010_000_0000_1_0001_00000000"), --[ 4|00000100] {OMEDELBAR} ASR := PC, PC++, uPC:= K1
        STD_LOGIC_VECTOR'(b"100_000_0000_0_0000_00000000"), --[ 5|00000101] ASR := IR
        STD_LOGIC_VECTOR'(b"001_000_0000_0_0001_00000000"), --[ 6|00000110] {INDIREKT}  ASR:= PM, uPC:= K1
        STD_LOGIC_VECTOR'(b"100_011_0100_0_0000_00000000"), --[ 7|00000111] {INDEXERAD} AR := IR
        STD_LOGIC_VECTOR'(b"101_011_0011_0_0000_00000000"), --[ 8|00001000] AR += GR3 (GR3 styrs av M)
        STD_LOGIC_VECTOR'(b"011_000_0000_0_0001_00000000"), --[ 9|00001001] ASR := AR, uPC := K1

        -- EXEKVERING
        STD_LOGIC_VECTOR'(b"001_101_0000_0_0011_00000000"), --[10|00001010] {LOAD} GRx := PM
        STD_LOGIC_VECTOR'(b"101_001_0000_0_0011_00000000"), --[11|00001011] {STORE} PM := GRx
        STD_LOGIC_VECTOR'(b"101_011_0100_0_0000_00000000"), --[12|00001100] {ADD} AR := GRx
        STD_LOGIC_VECTOR'(b"001_011_0001_0_0000_00000000"), --[13|00001101] AR += PM
        STD_LOGIC_VECTOR'(b"011_101_0000_0_0011_00000000"), --[14|00001110] GRx := AR
        STD_LOGIC_VECTOR'(b"101_011_0100_0_0000_00000000"), --[15|00001111] {SUB} AR := GRx
        STD_LOGIC_VECTOR'(b"001_011_0010_0_0000_00000000"), --[16|00010000] AR := GRx - PM
        STD_LOGIC_VECTOR'(b"011_101_0000_0_0011_00000000"), --[17|00010001] GRx := AR
        STD_LOGIC_VECTOR'(b"101_011_0000_0_0000_00000000"), --[18|00010010] {CMP} AR := GRx
        STD_LOGIC_VECTOR'(b"001_011_0000_0_0000_00000000"), --[19|00010011] AR := GRx AND PM    TODO: change ALU to CMP alu
        STD_LOGIC_VECTOR'(b"011_101_0000_0_0011_00000000"), --[20|00010100] GRx := AR
        STD_LOGIC_VECTOR'(b"101_011_0000_0_0000_00000000"), --[21|00010101] {AND} AR := GRx
        STD_LOGIC_VECTOR'(b"001_011_0000_0_0000_00000000"), --[22|00010110] AR := GRx AND PM    TODO change ALU to AND alu
        STD_LOGIC_VECTOR'(b"011_101_0000_0_0011_00000000"), --[23|00010111] GRx := AR
        STD_LOGIC_VECTOR'(b"101_011_0000_0_0000_00000000"), --[24|00011000] {MUL} AR := GRx
        STD_LOGIC_VECTOR'(b"001_011_0011_0_0000_00000000"), --[25|00011001] AR := GRx * PM 
        STD_LOGIC_VECTOR'(b"011_101_0000_0_0011_00000000"), --[26|00011010] GRx := AR
        STD_LOGIC_VECTOR'(b"101_011_0000_0_0000_00000000"), --[27|00011011] {OR} AR := GRx
        STD_LOGIC_VECTOR'(b"001_011_0000_0_0000_00000000"), --[28|00011100] AR := GRx OR PM       TODO change ALU to OR alu
        STD_LOGIC_VECTOR'(b"011_101_0000_0_0011_00000000"), --[29|00011101] GRx := AR
        STD_LOGIC_VECTOR'(b"010_011_0100_0_0000_00000000"), --[30|00011110] {BRA} AR := PC
        STD_LOGIC_VECTOR'(b"100_011_0001_0_0000_00000000"), --[31|00011111] AR := AR(PC) + IR
        STD_LOGIC_VECTOR'(b"011_010_0000_0_0000_00000000"), --[32|00100000] PC := AR
        STD_LOGIC_VECTOR'(b"000_000_0000_0_0011_00000000"), --[33|00100001] PC++      TODO remove row and maybe add SEQ:=0011 ^^ 
        STD_LOGIC_VECTOR'(b"000_000_0000_0_0100" & b"00011110"/*BRA.b8*/), --[34|00100010] {BNE} if Z=0 jump to BRA
        STD_LOGIC_VECTOR'(b"000_000_0000_0_0011_00000000"), --[35|00100011] {BEQ} if Z=1 jump to BRA
        STD_LOGIC_VECTOR'(b"000_000_0000_0_0011_00000000"), --[36|00100100] {JSR}
        STD_LOGIC_VECTOR'(b"111_111_0000_0_1111_00000000"), --[37|00100101] {HALT}
        OTHERS => (OTHERS => 'U')
    );
BEGIN
    data <= u_mem_array(TO_INTEGER(address));
END ARCHITECTURE;