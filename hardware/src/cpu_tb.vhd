LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.stop;

ENTITY cpu_tb IS
END ENTITY;

ARCHITECTURE testbench OF cpu_tb IS
  -- Constants
  CONSTANT CLK_PERIOD : TIME := 10 ns;

  -- Signals
  SIGNAL clk_tb : STD_LOGIC := '0';
  SIGNAL rst_tb : STD_LOGIC := '0';

  SIGNAL clock_count_tb : NATURAL := 0;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  UUT : ENTITY work.cpu PORT MAP(
    clk => clk_tb,
    rst => rst_tb
    );

  -- Clock process
  clk_process : PROCESS
  BEGIN
    clk_tb <= '0';
    WAIT FOR CLK_PERIOD / 2;
    clk_tb <= '1';
    WAIT FOR CLK_PERIOD / 2;
  END PROCESS;

  clk_counter : PROCESS
  BEGIN
    WAIT UNTIL rising_edge(clk_tb);
    clock_count_tb <= clock_count_tb + 1; -- rising edge => increment clock count
  END PROCESS;

  -- Stimulus process
  stimulus_process : PROCESS
  BEGIN
    -- reset
    rst_tb <= '1';
    WAIT FOR CLK_PERIOD;
    rst_tb <= '0';
    WAIT FOR CLK_PERIOD;

    WAIT;

  END PROCESS;

END ARCHITECTURE;