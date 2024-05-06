LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.stop;

ENTITY cpu_tb IS
END ENTITY;

ARCHITECTURE testbench OF cpu_tb IS
  -- Constants
  CONSTANT CLK_PERIOD : TIME := 10 ns;
  CONSTANT MAX_CLK_COUNT : NATURAL := 1e3;

  -- Signals
  SIGNAL clk_tb : STD_LOGIC := '0';
  SIGNAL rst_tb : STD_LOGIC := '1';
  SIGNAL clock_count_tb : NATURAL := 0;

  COMPONENT main IS
    PORT (
      clk : IN STD_LOGIC; -- system clock
      btnC : IN STD_LOGIC; -- reset
      Hsync : OUT STD_LOGIC; -- horizontal sync
      Vsync : OUT STD_LOGIC; -- vertical sync
      vgaRed : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- VGA red
      vgaGreen : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- VGA green
      vgaBlue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- VGA blue
      -- PS2Clk  : in std_logic;                  -- PS2 clock
      -- PS2Data : in std_logic                 -- PS2 data
    );
  END COMPONENT;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  UUT : main PORT MAP(
    clk => clk_tb,
    btnC => rst_tb,
    Hsync => OPEN,
    Vsync => OPEN,
    vgaRed => OPEN,
    vgaGreen => OPEN,
    vgaBlue => OPEN
  );

  -- Clock process
  clk_process : PROCESS
  BEGIN
    WAIT FOR CLK_PERIOD / 2;
    clk_tb <= NOT clk_tb;
  END PROCESS;

  clk_counter : PROCESS (clk_tb)
  BEGIN
    IF rising_edge(clk_tb) THEN
      IF clock_count_tb > MAX_CLK_COUNT THEN
        REPORT "Simulation has continued for longer than MAX_CLOCK_CYCLES constant: " & INTEGER'image(MAX_CLK_COUNT) & ", stopping!";
        STOP;
      ELSE
        clock_count_tb <= clock_count_tb + 1;
      END IF;
    END IF;
  END PROCESS;

  stimulus_process : PROCESS
  BEGIN
    -- reset
    WAIT FOR CLK_PERIOD * 1.6;
    rst_tb <= '0';

    WAIT;

  END PROCESS;

END ARCHITECTURE;