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

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  UUT : ENTITY work.cpu PORT MAP(
    clk => clk_tb,
    rst => rst_tb
    );

  -- Clock process
  clk_process : PROCESS
  BEGIN
    WHILE now < CLK_PERIOD * 10 LOOP -- run for 100 clock cycles
      clk_tb <= '0';
      WAIT FOR CLK_PERIOD / 2;
      clk_tb <= '1';
      WAIT FOR CLK_PERIOD / 2;
    END LOOP;
    stop;
  END PROCESS clk_process;

  -- Stimulus process
  stimulus_process : PROCESS
  BEGIN
    -- reset
    rst_tb <= '1';
    WAIT FOR CLK_PERIOD;
    rst_tb <= '0';
    WAIT FOR CLK_PERIOD;

    WAIT;

  END PROCESS stimulus_process;

END ARCHITECTURE;