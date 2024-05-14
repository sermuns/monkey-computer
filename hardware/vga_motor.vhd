LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY vga_motor IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        vmem_address_out : OUT unsigned(6 DOWNTO 0); -- to ask the video memory
        vmem_data : IN STD_LOGIC_VECTOR(23 DOWNTO 0); -- from the video memory
        vga_hsync : OUT STD_LOGIC;
        vga_vsync : OUT STD_LOGIC;
        vga_red : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY vga_motor;

ARCHITECTURE behavioral OF vga_motor IS
    COMPONENT tile_rom IS
        PORT (
            clk : IN STD_LOGIC;
            address : IN unsigned(13 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

    -- Actual pixels which are displayed on the screen
    SIGNAL x_subpixel, x_subpixel1 : unsigned(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL y_subpixel, y_subpixel1 : unsigned(9 DOWNTO 0) := (OTHERS => '0');

    SIGNAL ClkDiv : unsigned(1 DOWNTO 0); -- Clock divisor, to generate 25 MHz signal
    SIGNAL Clk25 : STD_LOGIC; -- One pulse width 25 MHz signal

    SIGNAL blank1, blank2, blank : STD_LOGIC; -- blanking signal, with delayed versions
    SIGNAL Hsync, Hsync1 : STD_LOGIC;
    SIGNAL Vsync, Vsync1 : STD_LOGIC;

    -- 100 tiles
    SIGNAL col_counter : unsigned(4 DOWNTO 0); -- which row of the video memory
    SIGNAL current_tiletype : unsigned(5 DOWNTO 0); -- which tiletype is currently being displayed

    SIGNAL x_within_tile : unsigned(5 DOWNTO 0); -- value 0-47px
    SIGNAL y_within_tile : unsigned(5 DOWNTO 0); -- value 0-47px
    ALIAS x_macro_within_tile IS x_within_tile(5 DOWNTO 2); -- divided by 4, value 0-11mpx
    ALIAS y_macro_within_tile IS y_within_tile(5 DOWNTO 2); -- divided by 4, value 0-11mpx
    SIGNAL row_counter : unsigned(4 DOWNTO 0); -- which row of the tile is currently being displayed

    SIGNAL tile_rom_address : unsigned(13 DOWNTO 0); -- Address for tile ROM
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
    Clk25 <=
        '1' WHEN (ClkDiv = 0) ELSE
        '0';

    -- Implement your VGA motor controller logic here
    x_counter : PROCESS (rst, clk)
    BEGIN
        IF rst = '1' THEN
            x_subpixel <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF (Clk25 = '1') THEN
                IF (x_subpixel = 799) THEN -- increment to outer screen edge so 0-799
                    x_subpixel <= (OTHERS => '0');
                ELSE -- reset to 0 after 799
                    x_subpixel <= x_subpixel + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Vertical pixel counter
    y_counter : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            y_subpixel <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF clk25 = '1' THEN
                IF (x_subpixel = 799) THEN
                    IF (y_subpixel = 521) THEN
                        y_subpixel <= (OTHERS => '0');
                    ELSE
                        y_subpixel <= y_subpixel + 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    Hsync1 <=
        '0' WHEN (x_subpixel > 656) AND (x_subpixel < 752) ELSE
        '1';

    Vsync1 <=
        '0' WHEN (y_subpixel > 490) AND (y_subpixel <= 492) ELSE
        '1';

    blank1 <= -- outside of visible area
        '1' WHEN (x_subpixel > 640) OR (y_subpixel > 480) ELSE
        '0';

    x_within_tile_counter : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            x_within_tile <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF clk25 = '1' THEN
                IF (x_subpixel = 799) THEN -- TODO check if 800 or 799
                    x_within_tile <= (OTHERS => '0'); -- time to restart
                ELSIF (x_subpixel < 479) THEN -- change to 639
                    IF (x_within_tile = 47) THEN
                        x_within_tile <= (OTHERS => '0'); -- right edge of tile
                    ELSE
                        x_within_tile <= x_within_tile + 1;
                    END IF;
                ELSE
                    x_within_tile <= (OTHERS => '0'); -- outside of map
                END IF;
            END IF;
        END IF;
    END PROCESS;

    y_within_tile_counter : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            y_within_tile <= (OTHERS => '0');
        ELSIF rising_edge(clk) AND x_subpixel = 799 THEN
            IF clk25 = '1' THEN
                IF (y_subpixel = 521) THEN
                    y_within_tile <= (OTHERS => '0'); -- time to restart
                ELSIF (y_subpixel = 479) THEN
                    y_within_tile <= (OTHERS => '0'); -- outside of map
                ELSE
                    IF (y_within_tile = 47) THEN
                        y_within_tile <= (OTHERS => '0'); -- bottom edge of tile
                    ELSE
                        y_within_tile <= y_within_tile + 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    row_counter_procces : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            row_counter <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF clk25 = '1' THEN
                IF (x_subpixel = 479) THEN  --change to 639
                    IF (y_within_tile = 47) THEN
                        IF (y_subpixel = 479) THEN
                            row_counter <= (OTHERS => '0');
                        ELSE
                            row_counter <= row_counter + 1;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    vmem_address_counter : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            col_counter <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF clk25 = '1' THEN
                IF (x_subpixel = 479) THEN
                    col_counter <= (OTHERS => '0');
                ELSIF (x_within_tile = 47) THEN
                    col_counter <= col_counter + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            blank2 <= blank1;
            Hsync <= Hsync1;
            Vsync <= Vsync1;
            x_subpixel1 <= x_subpixel;
            y_subpixel1 <= y_subpixel;
        END IF;
    END PROCESS;

    vmem_address_out <= resize(col_counter + (10 * row_counter), 7);

    -- slice out the correct field from the video memory data
    current_tiletype <= unsigned(vmem_data(5 DOWNTO 0)) WHEN x_subpixel < 479 ELSE
        "000000"; -- could just make current_tiletype into a alias?
    
        -- TODO uncomment 2 rows below and change 123 and 163
        -- <= unsigned(vmem_data(5 DOWNTO 0)) WHEN x_subpixel > 495  -- MENU START
        -- ELSE "100110" --(38) black between menu and playing field
        
        -- TODO add 30 lines to VMEM (menu tile numbers), increase col counter to reset when it's 639 (end of screen)
        -- TODO add 10 tiles(one per monkey) with colored outline and one black tile(#38). ARRAY(0 TO 7055). TO TEST JUST COPY PASTE MONKEYS AND ADD A SINGLE YELLOW LINE

    --TODO what does each bit in the tile_rom_address mean? and what else does it affect?

    tile_rom_address <= to_unsigned(TO_INTEGER(x_macro_within_tile) + (12 * TO_INTEGER(y_macro_within_tile)) + (144 * TO_INTEGER(current_tiletype)), 14);

    tile_rom_inst : tile_rom
    PORT MAP(
        clk => clk,
        address => tile_rom_address,
        data_out => tile_rom_data_out
    );

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            vga_hsync <= Hsync;
            vga_vsync <= Vsync;
            blank <= blank2;
        END IF;
    END PROCESS;

    vga_red <= tile_rom_data_out(11 DOWNTO 8) WHEN blank = '0' ELSE
        (OTHERS => '0');
    vga_green <= tile_rom_data_out(7 DOWNTO 4) WHEN blank = '0' ELSE
        (OTHERS => '0');
    vga_blue <= tile_rom_data_out(3 DOWNTO 0) WHEN blank = '0' ELSE
        (OTHERS => '0');

END ARCHITECTURE behavioral;