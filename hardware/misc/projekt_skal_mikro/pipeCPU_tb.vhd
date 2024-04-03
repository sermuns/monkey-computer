library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pipeCPU_tb is
end pipeCPU_tb;

architecture sim of pipeCPU_tb is

component pipeCPU is
	port(
		clk : in std_logic;
		btnC : in std_logic
		);
end component;

	signal clk : std_logic;
	signal rst : std_logic;
	
begin

	U0 : pipeCPU port map(
		clk => clk,
		btnC => rst
	);
	
	process
	begin
	
		for i in 0 to 450 loop
			clk <= '0';
			wait for 5 ns;
			clk <= '1';
			wait for 5 ns;
		end loop;
		
		wait; -- wait forever, will finish simulation
	end process;
	
	rst <= '1', '0' after 7 ns;
	
end architecture;
