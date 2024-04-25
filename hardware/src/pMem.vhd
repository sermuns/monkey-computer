LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        rst : IN STD_LOGIC;
        cpu_address : IN unsigned(11 DOWNTO 0);
        cpu_data_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        cpu_data_in : IN unsigned(23 DOWNTO 0);
        cpu_we : IN STD_LOGIC;
        video_address : IN unsigned(7 DOWNTO 0);
        video_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS
    CONSTANT VMEM_START : INTEGER := 1500;
    TYPE p_mem_type IS ARRAY(0 TO 4095) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    CONSTANT p_mem_init : p_mem_type := (
        -- PROGRAM MEMORY
        0 => b"00000_000_01_00_------------",
        1 => b"000000000000000000000001",
        2 => b"01010_000_00_00_111111111011",
        3 => b"11111_000_00_00_000000000000",

        -- VIDEO MEMORY
        VMEM_START + 00 => b"000000_000000_000000_000000",
        VMEM_START + 01 => b"000000_000000_000000_000000",
        VMEM_START + 02 => b"000000_000000_000000_011001",
        VMEM_START + 03 => b"011001_011001_011001_011001",
        VMEM_START + 04 => b"011001_011001_011001_000000",
        VMEM_START + 05 => b"000000_011001_000000_000000",
        VMEM_START + 06 => b"000000_000000_011001_000000",
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

        -- STACK

        OTHERS => (OTHERS => 'U')
    );
    SIGNAL p_mem : p_mem_type;

BEGIN
    -- LOAD
    cpu_data_out <= p_mem(TO_INTEGER(cpu_address));

    -- STORE
    PROCESS (cpu_we)
    BEGIN
        IF (rst = '1') THEN
            p_mem <= p_mem_init;
        ELSIF (cpu_we = '1') THEN
            IF (cpu_address >= p_mem'LENGTH) THEN
                REPORT "pMem address " & INTEGER'image(to_integer(unsigned(cpu_address))) & " out of range" SEVERITY FAILURE;
            ELSIF (cpu_we = '1') THEN
                p_mem(TO_INTEGER(cpu_address)) <= STD_LOGIC_VECTOR(cpu_data_in);
            END IF;
        END IF;
    END PROCESS;

    -- VIDEO 
    video_data <= p_mem(TO_INTEGER(video_address) + VMEM_START);
END ARCHITECTURE;