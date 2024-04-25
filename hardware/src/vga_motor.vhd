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
        vga_blue : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        Hsync : OUT STD_LOGIC;
        Vsync : OUT STD_LOGIC
    );
END ENTITY vga_motor;

ARCHITECTURE behavioral OF vga_motor IS
    -- Define your signals and variables here

    --"Actual" pixels
    SIGNAL X_subpixel : unsigned(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Y_subpixel : unsigned(9 DOWNTO 0) := (OTHERS => '0'); -- Vertical pixel counter

    --"logical" pixels used in tilerom
    SIGNAL X_macropixel : unsigned(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Y_macropixel : unsigned(9 DOWNTO 0) := (OTHERS => '0');

    SIGNAL X_subpixels_since_macro : unsigned(1 DOWNTO 0);
    SIGNAL Y_subpixels_since_macro : unsigned(1 DOWNTO 0);

    SIGNAL Xpixel1, Xpixel2 : unsigned(9 DOWNTO 0) := (OTHERS => '0'); --Horizontal pixel counter, AND its pipelined version
    SIGNAL Ypixel1, Ypixel2 : unsigned(9 DOWNTO 0) := (OTHERS => '0'); -- Vertical pixel counter
    SIGNAL ClkDiv : unsigned(1 DOWNTO 0); -- Clock divisor, to generate 25 MHz signal
    SIGNAL Clk25 : STD_LOGIC; -- One pulse width 25 MHz signal

    SIGNAL blank1, blank2, blank : STD_LOGIC; -- blanking signal, with delayed versions+
    SIGNAL Hsync1, Hsync2 : STD_LOGIC;
    SIGNAL Vsync1, Vsync2 : STD_LOGIC;

    SIGNAL tile_ROM_address : unsigned(13 DOWNTO 0); -- Address for tile ROM
    SIGNAL tile_rom_data_out : STD_LOGIC_VECTOR(11 DOWNTO 0); -- Data from tile ROM

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
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                Xpixel1 <= (OTHERS => '0');
                X_subpixels_since_macro <= (OTHERS => '0');
            ELSIF (Clk25 = '1') THEN
                IF (Xpixel1 < 800) THEN
                    Xpixel1 <= Xpixel1 + 1;
                    IF (X_subpixels_since_macro = "00") THEN
                        IF (X_macropixel = to_unsigned(12, X_macropixel'length)) THEN
                            X_macropixel <= (OTHERS => '0');
                        ELSE
                            X_macropixel <= X_macropixel + 1;
                        END IF;
                    END IF;
                    X_subpixels_since_macro <= X_subpixels_since_macro + 1;
                ELSE
                    Xpixel1 <= (OTHERS => '0');
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Horizontal sync
    Hsync1 <= '0' WHEN (Xpixel1 > 656) AND (Xpixel1 < 752) ELSE
        '1';

    -- Vertical pixel counter
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                Ypixel1 <= (OTHERS => '0');
                Y_subpixels_since_macro <= (OTHERS => '0');
            ELSIF (Xpixel1 = 800 AND Clk25 = '1') THEN
                IF (Ypixel1 >= 521) THEN
                    Ypixel1 <= (OTHERS => '0');
                ELSE
                    Y_subpixel <= Y_subpixel + 1;
                    IF (X_macropixel = to_unsigned(12, X_macropixel'length) AND Y_subpixels_since_macro = "00") THEN
                        IF (Y_macropixel = to_unsigned(12, Y_macropixel'length)) THEN
                            Y_macropixel <= (OTHERS => '0') ;
                        ELSE
                            Y_macropixel <= Y_macropixel + 1;
                        END IF;
                    END IF;
                    Y_subpixels_since_macro <= Y_subpixels_since_macro + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    -- Vertical Sync
    Vsync1 <= '0' WHEN (Ypixel1 > 490) AND (Ypixel1 < 492) ELSE
        '1';

    Blank1 <= '1' WHEN (Xpixel1 > 640)
        OR (Ypixel1 > 480) ELSE
        '0';

    -- Video ram address composite
    -- VR_addr <= to_unsigned(20, 7) * Ypixel1(8 DOWNTO 5) + Xpixel1(9 DOWNTO 5);

    -- VIDEO_RAM:
    -- data <= mem(addr), with one clock cycle delay

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            blank2 <= blank1;
            Hsync2 <= Hsync1;
            Vsync2 <= Vsync1;
            Xpixel2 <= Xpixel1;
            Ypixel2 <= Ypixel1;
        END IF;
    END PROCESS;

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            Hsync <= Hsync2;
            Vsync <= Vsync2;
            blank <= blank2;
        END IF;
    END PROCESS;

    -- port to tile ROM
    U0b : ENTITY work.tile_rom
        PORT MAP(
            address => tile_ROM_address,
            data => tile_rom_data_out
        );
    -- VGA output signals

END ARCHITECTURE behavioral;