-- VGA lab
-- Version 1.0: 2015-12-16. Anders Nilsson
-- Version 2.0: 2023-01-12. Petter Kallstrom. Changelog: Splitting KBD_ENC into KBD_ENC + PRETENDED_CPU
-- Version 3.0: 2023-09-29. Anders Nilsson. 12-bit VGA.


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity main is
	port (
		clk      : in std_logic;                         -- system clock
		rst     : in std_logic                         -- reset
		-- Hsync    : out std_logic;                        -- horizontal sync
		-- Vsync    : out std_logic;                        -- vertical sync
		-- vgaRed   : out std_logic_vector(3 downto 0);     -- VGA red
		-- vgaGreen : out std_logic_vector(3 downto 0);     -- VGA green
		-- vgaBlue  : out std_logic_vector(3 downto 0);     -- VGA blue
		-- PS2Clk  : in std_logic;                  -- PS2 clock
		-- PS2Data : in std_logic                 -- PS2 data
    );
end main;


-- architecture
architecture Behavioral of main is
	
	
	-- intermediate signals between CPU and VIDEO_RAM
	signal data_s : unsigned(23 downto 0); -- data
	signal addr_s : unsigned(11 downto 0);        -- address
	signal we_s   : std_logic;                    -- write enable
	
	-- intermediate signals between VIDEO_RAM and VGA_MOTOR
	signal data_out2_s : unsigned(7 downto 0); -- data
	signal addr2_s     : unsigned(10 downto 0);        -- address
	
begin
	
	-- keyboard encoder component connectio n
	-- U0 : kbd_enc port map(clk=>clk, rst=>btnC, PS2KeyboardCLK=>PS2Clk, PS2KeyboardData=>PS2Data, ScanCode=>ScanCode, make_op=>make_op);
	
	U1 : ENTITY work.cpu port map (
        clk => clk,
        rst => rst,
        v_addr => addr_s,
        v_data => data_s
    );
    
end Behavioral;

