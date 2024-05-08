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
    CONSTANT HEAP : INTEGER := 3000;

    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    SIGNAL p_mem : p_mem_type := (
        -- PROGRAM
        PROGRAM+0 => b"00000_000_00_00_010111011100", -- LD GR0, 1500 : loop
        PROGRAM+1 => b"00010_000_01_00_------------", -- ADDI GR0, 1 : loop
        PROGRAM+2 => b"000000000000000000000001", --  : 
        PROGRAM+3 => b"00001_000_00_00_010111011100", -- ST 1500, GR0 : loop 
        PROGRAM+4 => b"01010_---_00_00_000000000000", -- BRA loop : loop
        PROGRAM+5 => b"11111_---_--_--_------------", -- HALT : 
        -- VMEM
        VMEM+0 => b"000000000000000000000001", -- 0 : 
        VMEM+1 => b"000000000000000000000000", -- 0 : 
        VMEM+2 => b"000000000000000000011001", -- 25 : 
        VMEM+3 => b"011001011001011001011001", -- 6657625 : 
        VMEM+4 => b"011001011001011001000000", -- 6657600 : 
        VMEM+5 => b"000000011001000000000000", -- 102400 : 
        VMEM+6 => b"000000000000000000000000", -- 0 : 
        VMEM+7 => b"011001000000000000011001", -- 6553625 : 
        VMEM+8 => b"000000011001011001011001", -- 104025 : 
        VMEM+9 => b"011001011001011001000000", -- 6657600 : 
        VMEM+10 => b"011001011001000000011001", -- 6656025 : 
        VMEM+11 => b"000000000000000000000000", -- 0 : 
        VMEM+12 => b"000000000000000000000000", -- 0 : 
        VMEM+13 => b"000000011001000000011001", -- 102425 : 
        VMEM+14 => b"011001011001000000000000", -- 6656000 : 
        VMEM+15 => b"000000011001011001011001", -- 104025 : 
        VMEM+16 => b"000000011001000000011001", -- 102425 : 
        VMEM+17 => b"000000000000000000011001", -- 25 : 
        VMEM+18 => b"000000000000000000011001", -- 25 : 
        VMEM+19 => b"000000011001000000000000", -- 102400 : 
        VMEM+20 => b"000000011001011001011001", -- 104025 : 
        VMEM+21 => b"011001011001000000011001", -- 6656025 : 
        VMEM+22 => b"011001011001000000000000", -- 6656000 : 
        VMEM+23 => b"000000000000000000000000", -- 0 : 
        VMEM+24 => b"000000000000000000000000", -- 0 : 
        -- HEAP
        OTHERS => (OTHERS => '-')
    );

BEGIN

    -- Reading from two-port ram
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            cpu_data_out <= p_mem(TO_INTEGER(cpu_address) + PROGRAM);
        --    video_data <= b"000001_000001_000000_000001";
            -- TODO: THIS HARDCODED FUCKK 
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