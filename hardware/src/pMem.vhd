LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        adress : IN unsigned(11 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        in_data : IN STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS
    TYPE p_mem_type IS ARRAY(0 to 7) OF STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL p_mem : p_mem_type :=
    -- 00000_000_00_00_000000000000
    -- OP    GRx M  *  ADR 
    -- 5     3   2  2  12  
    (
    -- b"00000_101_01_00_000000000000", -- LOAD GR5, immediate
    -- b"00000_000_00_00_000000000010", -- 2
    -- b"00010_101_01_00_000000000000", -- ADD GR5, immediate
    -- b"00000_000_00_00_000000000001", -- 1
    -- b"00011_101_01_00_000000000000", -- SUB GR5, immediate
    -- b"00000_000_00_00_000000000001", -- 1
    -- b"01111_101_01_00_000000000000", -- MUL GR5, immediate
    -- b"00000_000_00_00_000000000100", -- 4
    b"00000_101_01_00_000000000000", -- Load GR5, immediate
    b"00000_000_00_00_000000000100", -- 5
    b"00001_101_00_00_000000000011", -- Store GR5 to memory adress 3
    b"00000_000_00_00_000000000000", -- WE SHOULD SEE WHATS STOREDDDD HERE :) 
    b"00000_000_00_00_000000000000",
    b"00000_000_00_00_000000000000",
    b"00000_000_00_00_000000000000",
    b"00000_000_00_00_000000000000"
    );
BEGIN
    PROCESS (in_data, adress)
    BEGIN
        p_mem(TO_INTEGER(adress)) <= in_data;
    END PROCESS;

    out_data <= p_mem(TO_INTEGER(adress));
END ARCHITECTURE;