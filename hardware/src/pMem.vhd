LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        rst : IN STD_LOGIC;
        adress : IN unsigned(11 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        in_data : IN unsigned(23 DOWNTO 0);
        should_store : IN STD_LOGIC;
        v_addr: OUT STD_LOGIC_VECTOR(23 downto 0);
        v_data: OUT STD_LOGIC_VECTOR(23 downto 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS
    TYPE p_mem_type IS ARRAY(0 TO 1023) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    CONSTANT p_mem_init : p_mem_type := (
        b"00010_000_01_00_------------",
        b"000011111111111111111111",
        b"00010_001_01_00_------------",
        b"000011111111111111111111",
        b"00010_010_01_00_------------",
        b"000011111111111111111111",
        b"00010_011_01_00_------------",
        b"000011111111111111111111",
        b"00010_100_01_00_------------",
        b"000011111111111111111111",
        b"00010_101_01_00_------------",
        b"000011111111111111111111",
        b"00010_110_01_00_------------",
        b"000011111111111111111111",
        b"00010_111_01_00_------------",
        b"000011111111111111111111",
        b"11111_000_00_00_000000000000",
        OTHERS => (OTHERS => 'U')
    );

    SIGNAL p_mem : p_mem_type;
BEGIN
    -- LOAD
    out_data <= p_mem(TO_INTEGER(adress));

    -- STORE
    PROCESS (should_store)
    BEGIN
        IF (rst = '1') THEN
            p_mem <= p_mem_init;
        ELSIF (should_store = '1') THEN
            IF (adress >= p_mem'LENGTH) THEN
                REPORT "pMem address " & INTEGER'image(to_integer(unsigned(adress))) & " out of range" SEVERITY FAILURE;
            ELSIF (should_store = '1') THEN
                p_mem(TO_INTEGER(adress)) <= STD_LOGIC_VECTOR(in_data);
            END IF;
        END IF;
    END PROCESS;

    -- VIDEO
    v_addr <= p_mem(TO_INTEGER(adress));
    v_data <= p_mem(TO_INTEGER(adress));

END ARCHITECTURE;