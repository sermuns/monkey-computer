LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uMem IS
    PORT (
        address : IN unsigned(7 DOWNTO 0);
        data : OUT STD_LOGIC_VECTOR(24 DOWNTO 0));
END uMem;

ARCHITECTURE func OF uMem IS
    TYPE u_mem_t IS ARRAY(0 TO 127) OF STD_LOGIC_VECTOR(24 DOWNTO 0);
    CONSTANT u_mem_array : u_mem_t := (
        -- 000_000_0000_0_00_0000_00000000
        -- TB _FB _ALU_ P_S_ SEQ _uADR

        -- HAMTNING
        b"010_000_0000_0_00_0000_--------",--[ 0|00000000] ASR := PC
        b"111_111_0000_0_00_0000_--------",--[ 1|00000001] NOOP
        b"001_100_0000_1_00_0000_--------",--[ 2|00000010] IR := PM, PC++
        b"111_111_0000_0_00_0010_--------",--[ 3|00000011] uPC := K2

        -- ADDRESSERING
        b"111_111_0000_0_00_0000_--------",--[ 4|00000100] NOOP *never taken*
        b"100_000_0000_0_00_0000_--------",--[ 5|00000101] {DIREKT} ASR := IR
        b"111_111_0000_0_00_0001_--------",--[ 6|00000110] uPC:= K1
        b"010_000_0000_1_00_0000_--------",--[ 7|00000111] {OMEDELBAR} ASR := PC, PC++
        b"100_000_0000_0_00_0001_--------",--[ 8|00001000] ASR := IR, uPC:= K1
        b"001_000_0000_0_00_0001_--------",--[ 9|00001001] {INDIREKT}  ASR:= PM, uPC:= K1
        b"100_011_0100_0_00_0000_--------",--[10|00001010] {INDEXERAD} AR := IR
        b"101_011_0011_0_00_0000_--------",--[11|00001011] AR += GR3 (GR3 styrs av M)
        b"011_000_0000_0_00_0001_--------",--[12|00001100] ASR := AR, uPC := K1

        -- EXEKVERING
        b"001_101_0000_0_00_0011_--------",--[13|00001101] {LOAD} GRx := PM
        b"101_001_0000_0_00_0011_--------",--[14|00001110] {STORE} PM := GRx
        b"101_011_0100_0_00_0000_--------",--[15|00001111] {ADD} AR := GRx
        b"001_011_0001_0_00_0000_--------",--[16|00010000] AR += PM
        b"011_101_0000_0_00_0011_--------",--[17|00010001] GRx := AR
        b"101_011_0100_0_00_0000_--------",--[18|00010010] {SUB} AR := GRx
        b"001_011_0010_0_00_0000_--------",--[19|00010011] AR := GRx - PM
        b"011_101_0000_0_00_0011_--------",--[20|00010100] GRx := AR
        b"101_011_0000_0_00_0000_--------",--[21|00010101] {CMP} AR := GRx
        b"001_011_1001_0_00_0000_--------",--[22|00010110] AR := GRx AND PM
        b"011_101_0000_0_00_0011_--------",--[23|00010111] GRx := AR
        b"101_011_0100_0_00_0000_--------",--[24|00011000] {AND} AR := GRx
        b"001_011_0101_0_00_0000_--------",--[25|00011001] AR := GRx AND PM
        b"011_101_0000_0_00_0011_--------",--[26|00011010] GRx := AR
        b"101_011_0000_0_00_0000_--------",--[27|00011011] {LSR} AR := GRx
        b"001_011_0111_0_00_0000_--------",--[28|00011100] AR := GRx >> PM
        b"101_011_0000_0_00_0000_--------",--[29|00011101] {MUL} AR := GRx
        b"001_011_0011_0_00_0000_--------",--[30|00011110] AR := GRx * PM 
        b"011_101_0000_0_00_0011_--------",--[31|00011111] GRx := AR
        b"101_011_0100_0_00_0000_--------",--[32|00100000] {OR} AR := GRx
        b"001_011_0110_0_00_0000_--------",--[33|00100001] AR := GRx OR PM
        b"011_101_0000_0_00_0011_--------",--[34|00100010] GRx := AR
        b"010_011_0100_0_00_0000_--------",--[35|00100011] {BRA} AR := PC
        b"100_011_0001_0_00_0000_--------",--[36|00100100] AR += IR
        b"011_010_0000_0_00_0011_--------",--[37|00100101] PC := AR + 1
        b"000_000_0000_0_00_0100_00100000",--[38|00100110] {BNE} if Z=0 jump to BRA   TODO: figure out status flags
        b"000_000_0000_0_00_0011_--------",--[39|00100111] uPC = 0, PC++
        b"000_000_0000_0_00_0110_00100000",--[40|00101000] {BEQ} if Z=1 jump to BRA   TODO: figure out status flags
        b"000_000_0000_0_00_0011_--------",--[41|00101001] uPC := 0, PC++
        b"110_000_0000_0_00_0000_--------",--[42|00101010] {JSR} ASR := SP,
        b"010_001_0000_0_01_0000_--------",--[43|00101011] PM(ASR) := PC, sp-- 
        b"110_000_0000_0_00_0101_00100000",--[44|00101100] ASR uPC = BRA
        b"110_000_0000_0_00_0000_--------",--[45|00101101] {PUSH} ASR:=SP, 
        b"101_001_0000_0_01_0011_--------",--[46|00101110] PM(ASR) := GRx, sp--
        b"000_000_0000_0_10_0000_--------",--[47|00101111] {POP} SP++
        b"110_000_0000_0_00_0000_--------",--[48|00110000] ASR:=SP, 
        b"001_101_0000_0_00_0011_--------",--[49|00110001] GRx := PM(ASR),
        b"110_000_0000_0_00_0000_--------",--[50|00110010] {RET} PM(ASR) := PC,
        b"001_010_0000_0_10_0011_--------",--[51|00110011] PC = PM(SP), sp++, uPC = 0
        b"111_111_0000_0_00_1111_--------",--[52|00110100] {HALT}
       OTHERS => (OTHERS => '0')
    );
BEGIN
    -- PROCESS (clk) IS
    -- BEGIN
    --     IF rising_edge(clk) THEN
    --         data <= u_mem_array(TO_INTEGER(address));
    --     END IF;
    -- END PROCESS;
            data <= u_mem_array(TO_INTEGER(address));
END ARCHITECTURE;