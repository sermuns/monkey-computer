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
        video_address: in unsigned(7 downto 0);
        video_data: OUT STD_LOGIC_VECTOR(23 downto 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS
    CONSTANT VMEM_START : INTEGER := 1500;
    TYPE p_mem_type IS ARRAY(0 TO 2047) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    CONSTANT p_mem_init : p_mem_type := (
        0 => b"00000_100_01_00_------------",
        1 => b"000000000000000000001111",
        2 => b"00101_100_01_00_------------",
        3 => b"000000000000000000000001",
        4 => b"00110_100_01_00_------------",
        5 => b"000000000000000000001000",
        6 => b"00111_100_01_00_------------",
        7 => b"000000000000000000000001",
        8 => b"11111_000_00_00_000000000000",
        9 to VMEM_START => (OTHERS => 'U'),

        -- 000000_000000_000000_000000
        VMEM_START+1 => b"000000_000000_000000_000000",
        VMEM_START+2 => b"000000_000000_000000_000000",
        VMEM_START+3 => b"000000_000000_000000_000000",
        VMEM_START+4 => b"000000_000000_000000_000000",
        VMEM_START+5 => b"000000_000000_000000_000000",
        VMEM_START+6 => b"000000_000000_000000_000000",
        VMEM_START+7 => b"000000_000000_000000_000000",
        VMEM_START+8 => b"000000_000000_000000_000000",
        VMEM_START+9 => b"000000_000000_000000_000000",
        VMEM_START+10 => b"000000_000000_000000_000000",
        VMEM_START+11 => b"000000_000000_000000_000000",
        VMEM_START+12 => b"000000_000000_000000_000000",
        VMEM_START+13 => b"000000_000000_000000_000000",
        VMEM_START+14 => b"000000_000000_000000_000000",
        VMEM_START+15 => b"000000_000000_000000_000000",
        VMEM_START+16 => b"000000_000000_000000_000000",
        VMEM_START+17 => b"000000_000000_000000_000000",
        VMEM_START+18 => b"000000_000000_000000_000000",
        VMEM_START+19 => b"000000_000000_000000_000000",
        VMEM_START+20 => b"000000_000000_000000_000000",
        VMEM_START+21 => b"000000_000000_000000_000000",
        VMEM_START+22 => b"000000_000000_000000_000000",
        VMEM_START+23 => b"000000_000000_000000_000000",
        VMEM_START+24 => b"000000_000000_000000_000000",
        VMEM_START+25 => b"000000_000000_000000_000000",
        others => (others => 'U')
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