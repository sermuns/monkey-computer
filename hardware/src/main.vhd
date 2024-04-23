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
		rst     : in std_logic;                         -- reset
		Hsync    : out std_logic;                        -- horizontal sync
		Vsync    : out std_logic;                        -- vertical sync
		vgaRed   : out std_logic_vector(7 downto 0);     -- VGA red
		vgaGreen : out std_logic_vector(7 downto 0);     -- VGA green
		vgaBlue  : out std_logic_vector(7 downto 0)    -- VGA blue
		-- PS2Clk  : in std_logic;                  -- PS2 clock
		-- PS2Data : in std_logic                 -- PS2 data
    );
end main;


-- architecture
architecture Behavioral of main is
	
	signal video_data : std_logic_vector(23 downto 0); -- data
	signal video_address : unsigned(7 downto 0);        -- address
	
begin
	
	-- keyboard encoder component connectio n
	-- U0 : kbd_enc port map(clk=>clk, rst=>btnC, PS2KeyboardCLK=>PS2Clk, PS2KeyboardData=>PS2Data, ScanCode=>ScanCode, make_op=>make_op);
	
	U1 : ENTITY work.cpu port map (
        clk => clk,
        rst => rst,
        v_addr => video_address,
        v_data => video_data
    );

	U2 : entity work.VGA_MOTOR port map (
		clk => clk,
		rst => rst,
		video_addr => video_address,
		video_data => video_data,
		vga_hsync => Hsync,
		vga_vsync => Vsync,
		vga_red => vgaRed,
		vga_green => vgaGreen,
		vga_blue => vgaBlue
		);

end architecture;