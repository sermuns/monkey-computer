library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- usage: 
-- give uAddr, get uData at that address
entity uMem is
    port(uAddr : in unsigned(7 downto 0);
        uData : out unsigned(23 downto 0));
end uMem;

architecture func of uMem is
    type u_mem_t is array(1000 downto 0) of unsigned(23 downto 0);
        constant u_mem_c : u_mem_t :=
        -- "000_000_0000_0_0000_000000000" = "TB_FB_ALU_P_SEQ_uADR"
        (
        b"010_000_0000_0_0000_000000000", -- ASR := PC
        b"001_100_0000_1_0101_000000000", -- IR := PM, PC := PC + 1, uPC := uADR  
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000",
        b"000_000_0000_0_0000_000000000"
        );
signal u_mem : u_mem_t := u_mem_c;

begin 
    uData <= u_mem(TO_INTEGER(uAddr));
end architecture;