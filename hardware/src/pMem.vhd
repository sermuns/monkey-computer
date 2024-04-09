LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        adress : IN unsigned(11 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        in_data : IN unsigned(23 DOWNTO 0);
        op : IN STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS
    TYPE p_mem_type IS ARRAY(0 TO 1023) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    SIGNAL p_mem : p_mem_type :=
    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    (
    b"00000_101_01_00_000000000000", -- Load GR5, immediate 4
    b"00000_000_00_00_000000000100",
    b"00001_101_00_00_000000000110", -- Store GR5

    OTHERS => (OTHERS => '0') -- fill with zeroes
    );

    CONSTANT load_op : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
    CONSTANT store_op : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001";
BEGIN
    PROCESS (op, adress, in_data)
    BEGIN
        IF (adress >= p_mem'LENGTH) THEN
            REPORT "pMem address " & INTEGER'image(to_integer(unsigned(adress))) & " out of range" SEVERITY FAILURE;
        END IF;

        IF op = load_op THEN
            out_data <= p_mem(TO_INTEGER(adress));
        ELSIF op = store_op THEN
            p_mem(TO_INTEGER(adress)) <= STD_LOGIC_VECTOR(in_data);
        END IF;
    END PROCESS;
END ARCHITECTURE;