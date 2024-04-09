LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.stop;

ENTITY ALU_ent_tb IS
END ENTITY ALU_ent_tb;

ARCHITECTURE testbench OF ALU_ent_tb IS
  -- Constants
  CONSTANT CLK_PERIOD : TIME := 10 ns;

  -- Signals
  SIGNAL A_tb : unsigned(23 DOWNTO 0) := (OTHERS => '0');
  SIGNAL B_tb : unsigned(23 DOWNTO 0) := (OTHERS => '0');
  SIGNAL ALU_op_tb : unsigned(3 DOWNTO 0) := (OTHERS => '0');
  SIGNAL result_tb : unsigned(23 DOWNTO 0);
  SIGNAL clk_tb : STD_LOGIC := '0';
  SIGNAL rst_tb : STD_LOGIC := '0';

BEGIN
  -- Instantiate ALU entity
  DUT : ENTITY work.ALU_ent
    PORT MAP(
      data_bus => A_tb,
      AR => B_tb,
      op => ALU_op_tb,
      result => result_tb,
      clk => clk_tb,
      rst => rst_tb
    );

  -- Clock process
  clk_process : PROCESS
  BEGIN
    WHILE now < 1000 ns LOOP
      clk_tb <= '0';
      WAIT FOR CLK_PERIOD / 2;
      clk_tb <= '1';
      WAIT FOR CLK_PERIOD / 2;
    END LOOP;
    WAIT;
  END PROCESS clk_process;

  -- Stimulus process
  stimulus_process : PROCESS
  BEGIN
    -- Apply reset
    rst_tb <= '1';
    WAIT FOR CLK_PERIOD;
    rst_tb <= '0';
    WAIT FOR CLK_PERIOD;

    -- Test 1: No operation
    A_tb <= "000000000000000000000001";
    B_tb <= "000000000000000000000010";
    ALU_op_tb <= "0000"; -- noop
    WAIT FOR CLK_PERIOD;
    -- Expected result: all zeros
    ASSERT result_tb = 000000000000000000000000
    REPORT "No-op failed" SEVERITY failure;

    -- Test 2: Addition
    A_tb <= "000000000000000000000001";
    B_tb <= "000000000000000000000010";
    ALU_op_tb <= "0001"; -- addition
    WAIT FOR CLK_PERIOD;
    -- Expected result: "000000000000000000000011"
    ASSERT result_tb = "000000000000000000000011"
    REPORT "Addition failed" SEVERITY failure;

    -- Test 3: Subtraction
    A_tb <= "000000000000000000000010";
    B_tb <= "000000000000000000000001";
    ALU_op_tb <= "0010"; -- subtraction
    WAIT FOR CLK_PERIOD;
    -- Expected result: "000000000000000000000001"
    ASSERT result_tb = "000000000000000000000001"
    REPORT "Subtraction failed" SEVERITY failure;

    -- Test 4: Multiplication
    A_tb <= "000000000000000000000010";
    B_tb <= "000000000000000000000010";
    ALU_op_tb <= "0011"; -- multiplication
    WAIT FOR CLK_PERIOD;
    -- Expected result: "000000000000000000000100"
    ASSERT result_tb = "000000000000000000000100"
    REPORT "Multiplication failed" SEVERITY failure;

    -- Test ended
    REPORT "Testbench successful!";
    stop;
  END PROCESS stimulus_process;

END ARCHITECTURE testbench;