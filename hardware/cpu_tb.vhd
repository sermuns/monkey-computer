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

  component main is
	port (
		clk      : in std_logic;                         -- system clock
		btnC     : in std_logic;                         -- reset
		Hsync    : out std_logic;                        -- horizontal sync
		Vsync    : out std_logic;                        -- vertical sync
		vgaRed   : out std_logic_vector(3 downto 0);     -- VGA red
		vgaGreen : out std_logic_vector(3 downto 0);     -- VGA green
		vgaBlue  : out std_logic_vector(3 downto 0)    -- VGA blue
		-- PS2Clk  : in std_logic;                  -- PS2 clock
		-- PS2Data : in std_logic                 -- PS2 data
    );
  end component;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  UUT : main PORT MAP(
    clk => clk_tb,
    btnC => rst_tb,
    Hsync => open,
    Vsync => open,
    vgaRed => open,
    vgaGreen => open,
    vgaBlue => open
    );

  -- Clock process
  clk_process : PROCESS
    VARIABLE clock_count_tb : NATURAL := 0;
  BEGIN
    WAIT FOR CLK_PERIOD / 2;
    clk_tb <= NOT clk_tb;

    IF now > CLK_PERIOD * MAX_CLK_COUNT THEN
      REPORT "Simulation has continued for longer than MAX_CLK_COUNT, stopping";
      STOP;
    END IF;

    IF rising_edge(clk_tb) THEN
      clock_count_tb := clock_count_tb + 1; -- rising edge => increment clock count
    END IF;
  END PROCESS;

  -- Stimulus process
  stimulus_process : PROCESS
  BEGIN
    -- reset
    WAIT FOR CLK_PERIOD * 1.6;
    rst_tb <= '0';

    WAIT;

  END PROCESS;

END ARCHITECTURE;