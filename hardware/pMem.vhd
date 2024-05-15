LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        clk : IN STD_LOGIC;
        cpu_address : IN unsigned(11 DOWNTO 0);
        cpu_data_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        cpu_data_in : IN unsigned(23 DOWNTO 0);
        cpu_we : IN STD_LOGIC;
        video_address : IN unsigned(6 DOWNTO 0);
        video_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS

    TYPE p_mem_type IS ARRAY(0 TO 4095) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    CONSTANT PROGRAM : INTEGER := 0;
    CONSTANT VMEM : INTEGER := 1500;
    CONSTANT PATH : INTEGER := 1600;
    CONSTANT HEAP : INTEGER := 3000;

    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    SIGNAL p_mem : p_mem_type := (
        -- PROGRAM
        PROGRAM+0 => b"00000_010_01_00_------------", -- start : LDI GR2, 1
        PROGRAM+1 => b"000000000000000000000001", -- 
        PROGRAM+2 => b"00001_010_10_00_011010100100", -- STN 1700, GR2 // baloon spawn amount
        PROGRAM+3 => b"00000_000_01_00_------------", -- LDI GR0, 35 // CONSTANT: balloon tiletype
        PROGRAM+4 => b"000000000000000000100011", -- 
        PROGRAM+5 => b"00001_001_10_00_010111011100", -- loop : STN 1500, GR1 // replace tiletype that was overwritten
        PROGRAM+6 => b"10010_---_--_00_------------", -- MOV GR6, GR5
        PROGRAM+7 => b"00011_110_01_00_------------", -- SUBI GR6, 40
        PROGRAM+8 => b"000000000000000000101000", -- 
        PROGRAM+9 => b"01100_---_--_00_------------", -- BEQ take_dmg
        PROGRAM+10 => b"00011_010_01_00_------------", -- new_ballon : SUBI GR2, 0
        PROGRAM+11 => b"000000000000000000000000", -- 
        PROGRAM+12 => b"01100_---_--_00_------------", -- BEQ dead
        PROGRAM+13 => b"10010_---_--_00_------------", -- MOV GR3, GR5 // GR3 := GR5
        PROGRAM+14 => b"00000_100_10_00_011001000000", -- LDN GR4, 1600 // GR4 := PATH[GR3]
        PROGRAM+15 => b"10010_---_--_00_------------", -- MOV GR3, GR4 // GR3 := GR4
        PROGRAM+16 => b"00000_001_10_00_010111011100", -- LDN GR1, 1500 // GR1 := VMEM[GR3]
        PROGRAM+17 => b"00001_000_10_00_010111011100", -- STN 1500, GR0 // overwrite with balloon
        PROGRAM+18 => b"00000_111_01_00_------------", -- LDI GR7, 0b111111111111111111111111
        PROGRAM+19 => b"111111111111111111111111", -- 
        PROGRAM+20 => b"00011_111_01_00_------------", -- wait : SUBI GR7, 1
        PROGRAM+21 => b"000000000000000000000001", -- 
        PROGRAM+22 => b"01011_---_--_00_------------", -- BNE wait
        PROGRAM+23 => b"00010_101_01_00_------------", -- ADDI GR5, 1 // increment path index
        PROGRAM+24 => b"000000000000000000000001", -- 
        PROGRAM+25 => b"01010_---_00_00_000000000100", -- BRA loop
        PROGRAM+26 => b"00000_010_00_00_011010100100", -- take_dmg : LD GR2, 1700 ;b
        PROGRAM+27 => b"00011_010_01_00_------------", -- SUBI GR2, 1
        PROGRAM+28 => b"000000000000000000000001", -- 
        PROGRAM+29 => b"00001_010_00_00_011010100100", -- ST 1700, GR2
        PROGRAM+30 => b"00000_101_01_00_------------", -- LDI GR5, 0
        PROGRAM+31 => b"000000000000000000000000", -- 
        PROGRAM+32 => b"01010_---_00_00_000000001001", -- BRA new_ballon
        PROGRAM+33 => b"01010_---_00_00_000000100000", -- dead : BRA dead ;b
        PROGRAM+34 => b"11111_---_--_--_------------", -- HALT
        -- VMEM
        VMEM+0 => b"000000000000000000000000", -- 0
        VMEM+1 => b"000000000000000000000000", -- 0
        VMEM+2 => b"000000000000000000000000", -- 0
        VMEM+3 => b"000000000000000000000000", -- 0
        VMEM+4 => b"000000000000000000000000", -- 0
        VMEM+5 => b"000000000000000000000000", -- 0
        VMEM+6 => b"000000000000000000000000", -- 0
        VMEM+7 => b"000000000000000000000000", -- 0
        VMEM+8 => b"000000000000000000000000", -- 0
        VMEM+9 => b"000000000000000000000000", -- 0
        VMEM+10 => b"000000000000000000000000", -- 0
        VMEM+11 => b"000000000000000000011001", -- 25
        VMEM+12 => b"000000000000000000011001", -- 25
        VMEM+13 => b"000000000000000000011001", -- 25
        VMEM+14 => b"000000000000000000011001", -- 25
        VMEM+15 => b"000000000000000000011001", -- 25
        VMEM+16 => b"000000000000000000011001", -- 25
        VMEM+17 => b"000000000000000000011001", -- 25
        VMEM+18 => b"000000000000000000011001", -- 25
        VMEM+19 => b"000000000000000000000000", -- 0
        VMEM+20 => b"000000000000000000000000", -- 0
        VMEM+21 => b"000000000000000000011001", -- 25
        VMEM+22 => b"000000000000000000000000", -- 0
        VMEM+23 => b"000000000000000000000000", -- 0
        VMEM+24 => b"000000000000000000000000", -- 0
        VMEM+25 => b"000000000000000000000000", -- 0
        VMEM+26 => b"000000000000000000000000", -- 0
        VMEM+27 => b"000000000000000000000000", -- 0
        VMEM+28 => b"000000000000000000011001", -- 25
        VMEM+29 => b"000000000000000000000000", -- 0
        VMEM+30 => b"000000000000000000000000", -- 0
        VMEM+31 => b"000000000000000000011001", -- 25
        VMEM+32 => b"000000000000000000000000", -- 0
        VMEM+33 => b"000000000000000000011001", -- 25
        VMEM+34 => b"000000000000000000011001", -- 25
        VMEM+35 => b"000000000000000000011001", -- 25
        VMEM+36 => b"000000000000000000011001", -- 25
        VMEM+37 => b"000000000000000000011001", -- 25
        VMEM+38 => b"000000000000000000011001", -- 25
        VMEM+39 => b"000000000000000000000000", -- 0
        VMEM+40 => b"000000000000000000011001", -- 25
        VMEM+41 => b"000000000000000000011001", -- 25
        VMEM+42 => b"000000000000000000000000", -- 0
        VMEM+43 => b"000000000000000000011001", -- 25
        VMEM+44 => b"000000000000000000000000", -- 0
        VMEM+45 => b"000000000000000000000000", -- 0
        VMEM+46 => b"000000000000000000000000", -- 0
        VMEM+47 => b"000000000000000000000000", -- 0
        VMEM+48 => b"000000000000000000000000", -- 0
        VMEM+49 => b"000000000000000000000000", -- 0
        VMEM+50 => b"000000000000000000000000", -- 0
        VMEM+51 => b"000000000000000000000000", -- 0
        VMEM+52 => b"000000000000000000000000", -- 0
        VMEM+53 => b"000000000000000000011001", -- 25
        VMEM+54 => b"000000000000000000000000", -- 0
        VMEM+55 => b"000000000000000000011001", -- 25
        VMEM+56 => b"000000000000000000011001", -- 25
        VMEM+57 => b"000000000000000000011001", -- 25
        VMEM+58 => b"000000000000000000000000", -- 0
        VMEM+59 => b"000000000000000000000000", -- 0
        VMEM+60 => b"000000000000000000000000", -- 0
        VMEM+61 => b"000000000000000000011001", -- 25
        VMEM+62 => b"000000000000000000011001", -- 25
        VMEM+63 => b"000000000000000000011001", -- 25
        VMEM+64 => b"000000000000000000000000", -- 0
        VMEM+65 => b"000000000000000000011001", -- 25
        VMEM+66 => b"000000000000000000000000", -- 0
        VMEM+67 => b"000000000000000000011001", -- 25
        VMEM+68 => b"000000000000000000000000", -- 0
        VMEM+69 => b"000000000000000000000000", -- 0
        VMEM+70 => b"000000000000000000000000", -- 0
        VMEM+71 => b"000000000000000000011001", -- 25
        VMEM+72 => b"000000000000000000000000", -- 0
        VMEM+73 => b"000000000000000000000000", -- 0
        VMEM+74 => b"000000000000000000000000", -- 0
        VMEM+75 => b"000000000000000000011001", -- 25
        VMEM+76 => b"000000000000000000000000", -- 0
        VMEM+77 => b"000000000000000000011001", -- 25
        VMEM+78 => b"000000000000000000000000", -- 0
        VMEM+79 => b"000000000000000000000000", -- 0
        VMEM+80 => b"000000000000000000000000", -- 0
        VMEM+81 => b"000000000000000000011001", -- 25
        VMEM+82 => b"000000000000000000011001", -- 25
        VMEM+83 => b"000000000000000000011001", -- 25
        VMEM+84 => b"000000000000000000011001", -- 25
        VMEM+85 => b"000000000000000000011001", -- 25
        VMEM+86 => b"000000000000000000000000", -- 0
        VMEM+87 => b"000000000000000000011001", -- 25
        VMEM+88 => b"000000000000000000011001", -- 25
        VMEM+89 => b"000000000000000000011001", -- 25
        VMEM+90 => b"000000000000000000000000", -- 0
        VMEM+91 => b"000000000000000000000000", -- 0
        VMEM+92 => b"000000000000000000000000", -- 0
        VMEM+93 => b"000000000000000000000000", -- 0
        VMEM+94 => b"000000000000000000000000", -- 0
        VMEM+95 => b"000000000000000000000000", -- 0
        VMEM+96 => b"000000000000000000000000", -- 0
        VMEM+97 => b"000000000000000000000000", -- 0
        VMEM+98 => b"000000000000000000000000", -- 0
        VMEM+99 => b"000000000000000000000000", -- 0
        -- PATH
        PATH+0 => b"000000000000000000101000", -- 40
        PATH+1 => b"000000000000000000101001", -- 41
        PATH+2 => b"000000000000000000011111", -- 31
        PATH+3 => b"000000000000000000010101", -- 21
        PATH+4 => b"000000000000000000001011", -- 11
        PATH+5 => b"000000000000000000001100", -- 12
        PATH+6 => b"000000000000000000001101", -- 13
        PATH+7 => b"000000000000000000001110", -- 14
        PATH+8 => b"000000000000000000001111", -- 15
        PATH+9 => b"000000000000000000010000", -- 16
        PATH+10 => b"000000000000000000010001", -- 17
        PATH+11 => b"000000000000000000010010", -- 18
        PATH+12 => b"000000000000000000011100", -- 28
        PATH+13 => b"000000000000000000100110", -- 38
        PATH+14 => b"000000000000000000100101", -- 37
        PATH+15 => b"000000000000000000100100", -- 36
        PATH+16 => b"000000000000000000100011", -- 35
        PATH+17 => b"000000000000000000100010", -- 34
        PATH+18 => b"000000000000000000100001", -- 33
        PATH+19 => b"000000000000000000101011", -- 43
        PATH+20 => b"000000000000000000110101", -- 53
        PATH+21 => b"000000000000000000111111", -- 63
        PATH+22 => b"000000000000000000111110", -- 62
        PATH+23 => b"000000000000000000111101", -- 61
        PATH+24 => b"000000000000000001000111", -- 71
        PATH+25 => b"000000000000000001010001", -- 81
        PATH+26 => b"000000000000000001010010", -- 82
        PATH+27 => b"000000000000000001010011", -- 83
        PATH+28 => b"000000000000000001010100", -- 84
        PATH+29 => b"000000000000000001010101", -- 85
        PATH+30 => b"000000000000000001001011", -- 75
        PATH+31 => b"000000000000000001000001", -- 65
        PATH+32 => b"000000000000000000110111", -- 55
        PATH+33 => b"000000000000000000111000", -- 56
        PATH+34 => b"000000000000000000111001", -- 57
        PATH+35 => b"000000000000000001000011", -- 67
        PATH+36 => b"000000000000000001001101", -- 77
        PATH+37 => b"000000000000000001010111", -- 87
        PATH+38 => b"000000000000000001011000", -- 88
        PATH+39 => b"000000000000000001011001", -- 89
        -- HEAP
        OTHERS => (OTHERS => '-')
    );

BEGIN

    -- Reading from two-port ram
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            cpu_data_out <= p_mem(TO_INTEGER(cpu_address) + PROGRAM);
            video_data <= p_mem(TO_INTEGER(video_address) + VMEM);
        END IF;
    END PROCESS;

    -- STORE
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (cpu_we = '1') THEN
                p_mem(TO_INTEGER(cpu_address)) <= STD_LOGIC_VECTOR(cpu_data_in);
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;