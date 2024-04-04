LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- usage: 
-- give uAddr, get uData at that address
ENTITY uMem IS
    PORT (
        address : IN unsigned(7 DOWNTO 0);
        data : OUT STD_LOGIC_VECTOR(22 DOWNTO 0));
END uMem;

ARCHITECTURE func OF uMem IS
    TYPE u_mem_t IS ARRAY(NATURAL RANGE <>) OF STD_LOGIC_VECTOR(22 DOWNTO 0);
    CONSTANT u_mem_array : u_mem_t :=
    -- "000_000_0000_0_0000_00000000" = "TB_FB_ALU_P_SEQ_uADR"
    (
    b"010_000_0000_0_0000_00000000", -- ASR := PC
    b"001_100_0000_1_0101_00000000", -- IR := PM, PC := PC + 1, uPC := uADR  
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000",
    b"000_000_0000_0_0000_00000000"
    );
BEGIN
    data <= u_mem_array(TO_INTEGER(address));
END ARCHITECTURE;