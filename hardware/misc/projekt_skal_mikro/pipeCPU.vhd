library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pipeCPU is
	port (
		clk : in std_logic;
		btnC : in std_logic     -- reset button (middle of the five), active high
	);
end pipeCPU;

architecture func of pipeCPU is

	signal clear : std_logic;       -- synchronous clear
  
	signal IR1 : unsigned(31 downto 0);
	alias IR1_op : unsigned(5 downto 0) is IR1(31 downto 26);
	alias IR1_d : unsigned(4 downto 0) is IR1(25 downto 21);
	alias IR1_a : unsigned(4 downto 0) is IR1(20 downto 16);
	alias IR1_b : unsigned(4 downto 0) is IR1(15 downto 11);
	alias IR1_c : unsigned(10 downto 0) is IR1(10 downto 0);

	signal IR2 : unsigned(31 downto 0);
	alias IR2_op : unsigned(5 downto 0) is IR2(31 downto 26);
	alias IR2_d : unsigned(4 downto 0) is IR2(25 downto 21);
	alias IR2_a : unsigned(4 downto 0) is IR2(20 downto 16);
	alias IR2_b : unsigned(4 downto 0) is IR2(15 downto 11);
	alias IR2_c : unsigned(10 downto 0) is IR2(10 downto 0);

	signal PC, PC1, PC2 : unsigned(10 downto 0);

	signal PMdata_out : unsigned(31 downto 0);
	signal pm_addr : unsigned(8 downto 0);

	constant iNOP : unsigned(5 downto 0) := "000000";
	constant iJ 	: unsigned(5 downto 0) := "010101";
	constant iBF 	: unsigned(5 downto 0) := "000100";

begin
	process(clk)
	begin
		if rising_edge(clk) then
			clear <= btnC; -- syncronize the reset signal
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if (rst='1') then
				PC <= (others => '0');
			elsif (IR2_op = iJ) then
				PC <= PC2;
			else
				PC <= PC + 1;
			end if;
		end if;
	end process;	

	pm_addr <= PC(8 downto 0);

	process(clk)
	begin
		if rising_edge(clk) then
			if (rst='1') then
				PC1 <= (others => '0');
			else
				PC1 <= PC;
			end if;
		end if;
	end process;	

	process(clk)
	begin
		if rising_edge(clk) then
			if (rst='1') then
				PC2 <= (others => '0');
			else
				PC2 <= PC1 + IR1_c;
			end if;
		end if;
	end process;	

	process(clk)
	begin
		if rising_edge(clk) then
			if (rst='1') then
				IR1 <= (others => '0');
			elsif (IR2_op = iJ) then
				IR1_op <= iNOP;
			else
				IR1 <= PMdata_out(31 downto 0);
			end if;
		end if;
	end process;


	process(clk)
	begin
		if rising_edge(clk) then
			if (rst='1') then
				IR2 <= (others => '0');
			else
				IR2 <= IR1;
			end if;
		end if;
	end process;


end architecture;
