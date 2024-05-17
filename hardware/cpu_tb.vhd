LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.stop;

ENTITY cpu_tb IS
END ENTITY;

ARCHITECTURE testbench OF cpu_tb IS
  -- Constants
  CONSTANT CLK_PERIOD : TIME := 10 ns;
  CONSTANT PS2_CLK_PERIOD : TIME := 60 us;
  CONSTANT PS2_TIME : TIME := 100 ns;

  -- Signals
  SIGNAL clk_tb : STD_LOGIC := '0';
  SIGNAL rst_tb : STD_LOGIC := '1';
  SIGNAL clock_count_tb : NATURAL := 0;

  SIGNAL PS2KeyboardCLK : STD_LOGIC;
  SIGNAL PS2KeyboardData : STD_LOGIC;

  COMPONENT main IS
    PORT (
      clk : IN STD_LOGIC; -- system clock
      btnC : IN STD_LOGIC; -- reset
      Hsync : OUT STD_LOGIC; -- horizontal sync
      Vsync : OUT STD_LOGIC; -- vertical sync
      vgaRed : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- VGA red
      vgaGreen : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- VGA green
      vgaBlue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- VGA blue
      PS2Clk : IN STD_LOGIC; -- PS2 clock
      PS2Data : IN STD_LOGIC -- PS2 data
    );
  END COMPONENT;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  UUT : main PORT MAP
  (
    clk => clk_tb,
    btnC => rst_tb,
    Hsync => OPEN,
    Vsync => OPEN,
    vgaRed => OPEN,
    vgaGreen => OPEN,
    vgaBlue => OPEN,
    PS2Clk => PS2KeyboardCLK,
    PS2Data => PS2KeyboardData
  );

  PS2_stimuli_proc : PROCESS
    TYPE pattern_array IS ARRAY(NATURAL RANGE <>) OF unsigned(7 DOWNTO 0);
    CONSTANT patterns : pattern_array :=
    (
    "00101001", -- x"1C" = Make scancode 'A'
    "11110000", -- x"F0" = Break ...
    "00011100", -- x"1C" = ... scancode 'A'
    "00110010", -- x"32" = Make scancode 'B'
    "11110000", -- x"F0" = Break ...
    "00110010", -- x"32" = ... scancode 'B'
    "00110101", -- x"35" = Make scancode 'Y'
    "11110000", -- x"F0" = Break ...
    "00101001", -- x"29" = ... scancode 'SPCAE'
    "11110000"
    );

  BEGIN
    PS2KeyboardData <= '1'; -- initial value
    PS2KeyboardCLK <= '1';
    -- WAIT FOR PS2_time;
    FOR i IN patterns'RANGE LOOP
      PS2KeyboardData <= '0'; -- start bit
      WAIT FOR PS2_clk_period/2;
      PS2KeyboardCLK <= '0';
      FOR j IN 0 TO 7 LOOP
        WAIT FOR PS2_clk_period/2;
        PS2KeyboardData <= patterns(i)(j); -- data bit(s)
        PS2KeyboardCLK <= '1';
        WAIT FOR PS2_clk_period/2;
        PS2KeyboardCLK <= '0'; -- data valid on negative flank
      END LOOP;
      WAIT FOR PS2_clk_period/2;
      PS2KeyboardData <= '0'; -- parity bit (bogus value, always '0')
      PS2KeyboardCLK <= '1';
      WAIT FOR PS2_clk_period/2;
      PS2KeyboardCLK <= '0';
      WAIT FOR PS2_clk_period/2;
      PS2KeyboardData <= '1'; -- stop bit
      PS2KeyboardCLK <= '1';
      WAIT FOR PS2_clk_period/2;
      PS2KeyboardCLK <= '0';
      WAIT FOR PS2_clk_period/2;
      PS2KeyboardCLK <= '1';
      IF (((i MOD 3) = 0) OR (((i + 1) MOD 3) = 0)) THEN
        WAIT FOR PS2_time; -- wait between Make and Break
      ELSE
        WAIT FOR PS2_clk_period/2;
      END IF;
    END LOOP;
    WAIT; -- for ever
  END PROCESS;

  -- Clock process
  clk_process : PROCESS
  BEGIN
    WAIT FOR CLK_PERIOD / 2;
    clk_tb <= NOT clk_tb;
  END PROCESS;

  clk_counter : PROCESS (clk_tb)
  BEGIN
    IF rising_edge(clk_tb) THEN
      clock_count_tb <= clock_count_tb + 1;
    END IF;
  END PROCESS;

  rst_stimuli_proc : PROCESS
  BEGIN
    -- reset
    WAIT FOR CLK_PERIOD * 1.6;
    rst_tb <= '0';

    WAIT;

  END PROCESS;

END ARCHITECTURE;