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
    CONSTANT VMEM_START : INTEGER := 1500;
    TYPE p_mem_type IS ARRAY(0 TO 4095) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    SIGNAL p_mem : p_mem_type := (
        -- PROGRAM MEMORY
        0 => b"00000_000_01_00_------------", -- LDI GR0, 1 --Loading different tiles into REGISTERS
        1 => b"000000000000000000000001",
        2 => b"00000_001_01_00_------------", -- LDI GR1, 2
        3 => b"000000000000000000000010",
        4 => b"00000_010_01_00_------------", -- LDI GR2, 3
        5 => b"000000000000000000000011",
        6 => b"00000_011_01_00_------------", -- LDI GR3, 4
        7 => b"000000000000000000000100",
        8 => b"00000_100_01_00_------------", -- LDI GR4, 5
        9 => b"000000000000000000000101",
        10 => b"00000_101_01_00_------------", -- LDI GR5, 6
        11 => b"000000000000000000000110",
        12 => b"00000_110_01_00_------------", -- LDI GR6, 7
        13 => b"000000000000000000000111",
        14 => b"00001_000_00_00_010111011101", -- ST 1501, GR0
        15 => b"00000_111_01_00_------------", -- LDI GR7, 9
        16 => b"000000000000000000001001",
        17 => b"01101_111_--_00_------------", -- PUSH GR7
        18 => b"00001_001_00_00_010111011110", -- ST 1502, GR1
        19 => b"00001_010_00_00_010111011111", -- ST 1503, GR2
        20 => b"00001_011_00_00_010111100000", -- ST 1504, GR3
        21 => b"00001_100_00_00_010111100001", -- ST 1505, GR4
        22 => b"00001_101_00_00_010111100010", -- ST 1506, GR5
        23 => b"00001_110_00_00_010111100011", -- ST 1507, GR6
        24 => b"10000_000_--_00_------------", -- RET --Check implementation sp might need to increment before last step. Should send us to  row 10
        25 => b"11111_---_--_--_------------", -- HALT

        -- VIDEO MEMORY
        VMEM_START + 00 => b"000001_000000_000000_000000",
        VMEM_START + 01 => b"000000_000000_000000_000000",
        VMEM_START + 02 => b"000000_000000_000000_011001",
        VMEM_START + 03 => b"011001_011001_011001_011001",
        VMEM_START + 04 => b"011001_011001_011001_000000",
        VMEM_START + 05 => b"000000_011001_000000_000000",
        VMEM_START + 06 => b"000000_000000_000000_000000",
        VMEM_START + 07 => b"011001_000000_000000_011001",
        VMEM_START + 08 => b"000000_011001_011001_011001",
        VMEM_START + 09 => b"011001_011001_011001_000000",
        VMEM_START + 10 => b"011001_011001_000000_011001",
        VMEM_START + 11 => b"000000_000000_000000_000000",
        VMEM_START + 12 => b"000000_000000_000000_000000",
        VMEM_START + 13 => b"000000_011001_000000_011001",
        VMEM_START + 14 => b"011001_011001_000000_000000",
        VMEM_START + 15 => b"000000_011001_011001_011001",
        VMEM_START + 16 => b"000000_011001_000000_011001",
        VMEM_START + 17 => b"000000_000000_000000_011001",
        VMEM_START + 18 => b"000000_000000_000000_011001",
        VMEM_START + 19 => b"000000_011001_000000_000000",
        VMEM_START + 20 => b"000000_011001_011001_011001",
        VMEM_START + 21 => b"011001_011001_000000_011001",
        VMEM_START + 22 => b"011001_011001_000000_000000",
        VMEM_START + 23 => b"000000_000000_000000_000000",
        VMEM_START + 24 => b"000000_000000_000000_000000",

        -- HEAP

        -- STACKcpu_we

        OTHERS => (OTHERS => '-')
    );

BEGIN



    -- Reading from two-port ram
    process(clk)
    begin
        if rising_edge(clk) then
            cpu_data_out <= p_mem(TO_INTEGER(cpu_address));
            end if;
        end process;

        -- TODO: THIS HARDCODED FUCKK 
            video_data <= b"000001_000001_000000_000001";
            
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