LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        rst : IN STD_LOGIC;
        adress : IN unsigned(11 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        in_data : IN unsigned(23 DOWNTO 0);
        should_store : IN STD_LOGIC
    );
END pMem;

ARCHITECTURE func OF pMem IS
    TYPE p_mem_type IS ARRAY(0 TO 1023) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    CONSTANT p_mem_init : p_mem_type := (
        -- 00000_000_00_00_000000000000
        -- OP    GRx M  *  ADR 
        -- 5     3   2  2  12  
        b"00000_111_01_00_000000000000", --Load GR7
        b"00000_000_00_00_111111111111", --immediate value
        b"00001_111_00_00_000000000111", --STORE GR7 in PM(7)
        b"11111_000_00_00_000000000000", --HALT
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
                REPORT "pMem address " & INTEGER'image(to_integer(unsigned(adress))) & " stored" SEVERITY note;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;