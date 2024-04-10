LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        adress : IN unsigned(11 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        in_data : IN unsigned(23 DOWNTO 0);
        op : IN STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS
    TYPE p_mem_type IS ARRAY(0 TO 1023) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    CONSTANT p_mem_init : p_mem_type :=
    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    (
    b"00000_111_01_00_000000000000", -- Load GR7
    b"00000_000_00_00_111111111111", -- immediate value
    b"00001_111_00_00_000000001001", -- STORE GR7 in PM(9)
    b"11111_000_00_00_000000000000", -- HALT
    OTHERS => (OTHERS => 'U') -- fill with undefined
    );

    SIGNAL p_mem : p_mem_type;

    CONSTANT store_op : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001";
BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF (rst = '1') THEN
            p_mem <= p_mem_init;
        ELSIF (rising_edge(clk)) THEN
            IF (adress >= p_mem'LENGTH) THEN
                REPORT "pMem address " & INTEGER'image(to_integer(unsigned(adress))) & " out of range" SEVERITY FAILURE;
            ELSIF (op = store_op) THEN
                p_mem(TO_INTEGER(adress)) <= STD_LOGIC_VECTOR(in_data);
                REPORT "pMem address " & INTEGER'image(to_integer(unsigned(adress))) & " stored" SEVERITY note;
            END IF;
        END IF;
        out_data <= p_mem(TO_INTEGER(adress));
    END PROCESS;
END ARCHITECTURE;