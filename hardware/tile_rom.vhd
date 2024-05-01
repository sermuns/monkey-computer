LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tile_rom IS
    PORT (
        clk : IN STD_LOGIC;
        address : IN UNSIGNED(13 DOWNTO 0); -- 14 bit address
        data_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
END tile_rom;

ARCHITECTURE func OF tile_rom IS TYPE palette_rom_type IS ARRAY(NATURAL RANGE <>) OF STD_LOGIC_VECTOR(11 DOWNTO 0);
    CONSTANT palette_rom : palette_rom_type := (        00 => x"ffffff",
        01 => x"000000",
        02 => x"332222",
        03 => x"404040",
        04 => x"f5a097",
        05 => x"774433",
        06 => x"993311",
        07 => x"cc8855",
        08 => x"ffdd55",
        09 => x"176b04",
        10 => x"44eebb",
        11 => x"3388dd",
        12 => x"070708",
        13 => x"555577",
        14 => x"5544aa",
        15 => x"422433",
        16 => x"73172d",
        17 => x"e86a73",
        18 => x"b4202a"
    );
    CONSTANT NUM_TILES : INTEGER := 32;
    CONSTANT TILE_SIZE : INTEGER := 12 * 12;

    TYPE tile_rom_type IS ARRAY(NATURAL RANGE <>) OF unsigned(4 DOWNTO 0);
    CONSTANT tile_rom_data : tile_rom_type := (
    );

    SIGNAL palette_index : unsigned(4 DOWNTO 0); -- max 32 colors
BEGIN
    -- get palette index from memory
    process(clk) BEGIN
        IF rising_edge(clk) THEN
            palette_index <= tile_rom_data(to_integer(address));
            data_out <= palette_rom(to_integer(palette_index));
        END IF;
    END PROCESS;
    -- palette_index <= tile_rom_data(to_integer(address));
    
    -- data_out <= palette_rom(to_integer(palette_index));
END ARCHITECTURE;