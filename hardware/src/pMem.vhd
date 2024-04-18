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
    TYPE p_mem_type IS ARRAY(0 TO 2047) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    CONSTANT p_mem_init : p_mem_type := (
        b"00000_000_01_00_------------",
        b"000000000000000000000001",
        b"00010_000_01_00_------------",
        b"000000000000000000000010",
        b"00010_001_01_00_------------",
        b"000011111111111111111111",
        b"00010_001_01_00_------------",
        b"000011111111111111111111",
        b"11111_000_00_00_000000000000",
        OTHERS => (OTHERS => 'U')
    );
    SIGNAL p_mem : p_mem_type;

    CONSTANT VMEM_START : INTEGER := 1500;
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