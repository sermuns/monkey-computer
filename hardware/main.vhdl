library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;


entity cpu is
    port(
        clk : in std_logic;
        rst : in std_logic);    
end cpu;

-- Architecture definition
architecture Behavioral of cpu is
component uMem

        port(uAddr : in unsigned(21 downto 0);
            uData : out unsigned(31 downto 0));
        end component;

component pMem

    port(pAddr : in unsigned(21 downto 0);
        pData : in unsigned(31 downto 0));

end component; 
    --TODO: HAVE A BIG CONVERSATION ABOUT THESE SIZES :D
    -- Signals for microcode memory
    signal uInst : unsigned(23 downto 0);
    alias TB : unsigned(2 downto 0) is uInst(23 downto 21);
    alias FB : unsigned(2 downto 0) is uInst(20 downto 18);
    alias ALU : unsigned(3 downto 0) is uInst(17 downto 14);
    alias P : std_logic is uInst(13);
    alias SEQ : unsigned(3 downto 0) is uInst(12 downto 9);
    alias ADR : unsigned(8 downto 0) is uInst(8 downto 0);

    -- Signals for program memory currently 22 bits 
    signal PM : unsigned (21 downto 0);

    signal PC : unsigned(21 downto 0);
    signal uPC : unsigned(8 downto 0);
    signal IR : unsigned(21 downto 0);
    signal ASR : unsigned(11 downto 0);

    signal DATA_BUS : unsigned(23 downto 0);
begin

ALU_inst: entity work.ALU
 port map(
    FB_val => FB,
    operation => ALU
);

end Behavioral;
