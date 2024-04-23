LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tile_rom IS
    PORT (
        address : IN UNSIGNED(13 DOWNTO 0); -- 14 bit address
        data : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
END tile_rom;

ARCHITECTURE func OF tile_rom IS
    TYPE palette_rom_type IS ARRAY(0 TO 10) OF STD_LOGIC_VECTOR(11 DOWNTO 0);
    CONSTANT palette_rom : palette_rom_type := (
        0 => X"000", --black
        1 => X"FFF", --white
        2 => X"F00", --red
        3 => X"0F0", --green
        4 => X"FA0", --orange, replace with appropriate value
        5 => X"F0A", --pink, replace with appropriate value
        6 => X"00F", --blue
        7 => X"0FF", --cyan, replace with appropriate value
        8 => X"FD0", --yellow
        9 => X"A50", --brown, replace with appropriate value
        10 => X"A52" --light brown, replace with appropriate value
    );

    TYPE tile_rom_type IS ARRAY(0 TO 2 ** 13 - 1) OF unsigned(4 DOWNTO 0);
    CONSTANT tile_rom_data : tile_rom_type := (
        --12x12

        -- 0: grass
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110", "00110",
        OTHERS => (OTHERS => 'U')

        -- 1: apa 1 frame 1
        -- 2: apa 1 frame 2
        -- 3: apa 1 frame 3
        -- 4: apa 1 frame 4

        --apa 2 frame 1
        --apa 2 frame 2
        --apa 2 frame 3
        --apa 2 frame 4

        --apa 3 frame 1
        --apa 3 frame 2
        --apa 3 frame 3
        --apa 3 frame 4

        --apa 4 frame 1
        --apa 4 frame 2
        --apa 4 frame 3
        --apa 4 frame 4

        --apa 5 frame 1
        --apa 5 frame 2
        --apa 5 frame 3
        --apa 5 frame 4

        --apa 6 frame 1
        --apa 6 frame 2
        --apa 6 frame 3
        --apa 6 frame 4

        --25:
        --26-29: ballon 1 frame 1-4 
        --30-33: ballon 2 frame 1-4 
        --34-37: ballon 3 frame 1-4 ORANGE
    );

    SIGNAL palette_index : unsigned(4 DOWNTO 0); -- max 32 colors
BEGIN
    PROCESS (address)
    BEGIN
        -- get palette index from memory
        palette_index <= tile_rom_data(to_integer(address));
        data <= palette_rom(to_integer(palette_index));
    END PROCESS;
END ARCHITECTURE;