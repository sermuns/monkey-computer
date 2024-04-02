library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;

entity ALU is
    port(
        FB_val : in unsigned(11 downto 0);
        val : out unsigned(11 downto 0);
        operation : in unsigned(3 downto 0)
        );    
end entity;

architecture Behavioral of ALU is
begin
    --And?
    --Shifts?
    process (operation, val)
    begin
        with operation select val <=
            FB_val when "0000",
            val + FB_val when "0001",
            val - FB_val when "0010",
            val * FB_val when "0011";
    end process;

end architecture Behavioral;