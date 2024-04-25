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

    -- Actual pixels which are displayed on the screen
    SIGNAL x_subpixel : unsigned(9 DOWNTO 0);
    SIGNAL y_subpixel : unsigned(9 DOWNTO 0);

    -- Logical pixels which the Tile ROM uses (4 subpixels = 1 pixel)
    ALIAS x_macropixel IS x_subpixel(9 DOWNTO 2);
    ALIAS y_macropixel IS y_subpixel(9 DOWNTO 2);

    SIGNAL ClkDiv : unsigned(1 DOWNTO 0); -- Clock divisor, to generate 25 MHz signal
    SIGNAL Clk25 : STD_LOGIC; -- One pulse width 25 MHz signal

    SIGNAL blank1, blank2, blank : STD_LOGIC; -- blanking signal, with delayed versions+
    SIGNAL Hsync1, Hsync2 : STD_LOGIC;
    SIGNAL Vsync1, Vsync2 : STD_LOGIC;

    -- 100 tiles
    SIGNAL tile_index : unsigned(7 DOWNTO 0);
    SIGNAL tile_col : unsigned(3 DOWNTO 0); -- max value 10: 10 tiles in row
    SIGNAL tile_row : unsigned(3 DOWNTO 0); -- max value 10: 10 rows

    SIGNAL vmem_address : unsigned(6 DOWNTO 0); -- 
    SIGNAL vmem_field : unsigned(1 DOWNTO 0); -- 4 fields

    SIGNAL x_within_tile : unsigned(5 DOWNTO 0); -- max value 48px
    SIGNAL y_within_tile : unsigned(5 DOWNTO 0); -- max value 48px

    SIGNAL tile_rom_address : unsigned(13 DOWNTO 0); -- Address for tile ROM
    SIGNAL tile_rom_data_out : STD_LOGIC_VECTOR(11 DOWNTO 0); -- Data from tile ROM

    CONSTANT TILE_SUBPIXEL_SIZE : INTEGER := 48; -- 48 subpixels per tile

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
    Clk25 <=
        '1' WHEN (ClkDiv = 0) ELSE
        '0';

    -- Implement your VGA motor controller logic here
    x_counter : PROCESS (rst, clk)
    BEGIN
        IF rst = '1' THEN
            x_subpixel <= to_unsigned(0, x_subpixel'LENGTH);
        ELSIF rising_edge(clk) THEN
            IF (Clk25 = '1') THEN
                IF (x_subpixel < 800) THEN
                    x_subpixel <= x_subpixel + 1;
                ELSE
                    x_subpixel <= (OTHERS => '0');
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Vertical pixel counter
    y_counter : PROCESS (clk)
    BEGIN
        IF rst = '1' THEN
            y_subpixel <= to_unsigned(0, y_subpixel'LENGTH);
        ELSIF rising_edge(clk) THEN
            IF (x_subpixel = 800 AND Clk25 = '1') THEN
                IF (y_subpixel ?< 520) THEN
                    y_subpixel <= y_subpixel + 1;
                ELSE
                    y_subpixel <= (OTHERS => '0');
                END IF;
            END IF;
        END IF;
    END PROCESS;

    Hsync1 <=
        '0' WHEN (x_subpixel > 656) AND (x_subpixel < 752) ELSE
        '1';

    Vsync1 <=
        '0' WHEN (y_subpixel > 490) AND (y_subpixel < 492) ELSE
        '1';

    Blank1 <= -- outside of visible area
        '1' WHEN (x_subpixel > 640) OR (y_subpixel > 480) ELSE
        '0';

    x_within_tile_counter : PROCESS (clk)
    BEGIN
        IF rst = '1' THEN
            x_within_tile <= (OTHERS => '0');
        ELSIF rising_edge(clk) AND clk25 = '1' THEN
            IF (x_subpixel < 479) THEN
                IF (x_within_tile < TILE_SUBPIXEL_SIZE - 1) THEN
                    x_within_tile <= x_within_tile + 1;
                ELSE
                    x_within_tile <= (OTHERS => '0'); -- right edge of tile
                END IF;
            ELSE
                x_within_tile <= (OTHERS => '-'); -- outside of map
            END IF;
        END IF;
    END PROCESS;

    y_within_tile_counter : PROCESS (clk)
    BEGIN
        IF rst = '1' THEN
            y_within_tile <= (OTHERS => '0');
        ELSIF rising_edge(clk) AND clk25 = '1' AND x_subpixel = 799 THEN
            IF (y_subpixel < 479) THEN
                IF (y_within_tile < TILE_SUBPIXEL_SIZE - 1) THEN
                    y_within_tile <= y_within_tile + 1;
                ELSE
                    y_within_tile <= (OTHERS => '0'); -- bottom edge of tile
                END IF;
            ELSE
                y_within_tile <= (OTHERS => '-'); -- outside of map
            END IF;
        END IF;
    END PROCESS;

    tile_col_counter : PROCESS (clk)
    BEGIN
        IF rst = '1' THEN
            tile_col <= (OTHERS => '0');
        ELSIF rising_edge(clk)
            AND Clk25 = '1'
            THEN
            IF (x_within_tile = 47) THEN
                IF (tile_col < 9) THEN
                    IF (x_subpixel < 479) THEN
                        tile_col <= tile_col + 1;
                    ELSE
                        tile_col <= (OTHERS => '-'); -- right edge of screen
                    END IF;
                ELSE
                    tile_col <= (OTHERS => '0'); -- right edge of screen
                END IF;
            END IF;
        END IF;
    END PROCESS;

    tile_row_counter : PROCESS (clk)
    BEGIN
        IF rst = '1' THEN
            tile_row <= (OTHERS => '0');
        ELSIF rising_edge(clk)
            AND Clk25 = '1'
            AND tile_col = 9
            AND y_within_tile = 47
            THEN
            IF (tile_row < 8) THEN
                tile_row <= tile_row + 1;
            ELSE
                tile_row <= (OTHERS => '0'); -- bottom of map
            END IF;
        END IF;
    END PROCESS;

    tile_rom_inst : ENTITY work.tile_rom
        PORT MAP(
            address => tile_rom_address,
            data => tile_rom_data_out
        );

END ARCHITECTURE behavioral;