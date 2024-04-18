LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY vga_motor IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        video_addr : OUT unsigned(7 DOWNTO 0); -- to ask the video memory
        video_data : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        vga_hsync : OUT STD_LOGIC;
        vga_vsync : OUT STD_LOGIC;
        vga_red : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        vga_green : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        vga_blue : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY vga_motor;

ARCHITECTURE behavioral OF vga_motor IS
    -- Define your signals and variables here
    SIGNAL Xpixel1, Xpixel2 : unsigned(9 DOWNTO 0) := (OTHERS => '0'); --Horizontal pixel counter, AND its pipelined version
    SIGNAL Ypixel1, Ypixel2 : unsigned(9 DOWNTO 0) := (OTHERS => '0'); -- Vertical pixel counter
    SIGNAL ClkDiv : unsigned(1 DOWNTO 0); -- Clock divisor, to generate 25 MHz signal
    SIGNAL Clk25 : STD_LOGIC; -- One pulse width 25 MHz signal

    SIGNAL blank1, blank2, blank : STD_LOGIC; -- blanking signal, with delayed versions
    SIGNAL Hsync1, Hsync2 : STD_LOGIC;
    SIGNAL Vsync1, Vsync2 : STD_LOGIC;

BEGIN
    -- Clock divisor
    -- Divide system clock (100 MHz) by 4
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            ClkDiv <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            ClkDiv <= ClkDiv + 1;
        END IF;
    END PROCESS;

    -- 25 MHz clock (one system clock pulse width)
    Clk25 <= '1' WHEN (ClkDiv = 3) ELSE
        '0';

    -- Implement your VGA motor controller logic here

END ARCHITECTURE behavioral;