LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;

ENTITY CPU_ent IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC);
END CPU_ent;

-- Architecture definition
ARCHITECTURE CPU_arch OF CPU_ent IS
  -- Microcode memory
  SIGNAL micro_instr : unsigned(23 DOWNTO 0); -- EX. "000_000_0000_0_0_0000_00000000" => "TB_FB_ALU_P_uP_SEQ_uADR"
  -- Fields of the microcode instruction
  ALIAS TB : unsigned(2 DOWNTO 0) IS micro_instr(23 DOWNTO 21);
  ALIAS FB : unsigned(2 DOWNTO 0) IS micro_instr(20 DOWNTO 18);
  ALIAS ALU_op : unsigned(3 DOWNTO 0) IS micro_instr(17 DOWNTO 14);
  ALIAS P : STD_LOGIC IS micro_instr(13);
  ALIAS SEQ : unsigned(3 DOWNTO 0) IS micro_instr(12 DOWNTO 9);
  ALIAS micro_ADR : unsigned(7 DOWNTO 0) IS micro_instr(8and DOWNTO 0);

  -- Main memory: program, heap and stack
  SIGNAL assembly_instr : unsigned (23 DOWNTO 0); -- EX. "00000_000_00_0000000000000" => "OP_GRx_M_ADR"
  -- Field of the assembly instruction
  ALIAS assembly_OP : unsigned(4 DOWNTO 0) IS assembly_instr(23 DOWNTO 19);
  ALIAS assembly_GRx : unsigned(2 DOWNTO 0) IS assembly_instr(18 DOWNTO 16);
  ALIAS assembly_M : unsigned(2 DOWNTO 0) IS assembly_instr(15 DOWNTO 14);
  ALIAS assembly_ADR : unsigned(8 DOWNTO 0) IS assembly_instr(13 DOWNTO 0);

  SIGNAL ALU_result : unsigned(23 DOWNTO 0);

  -- Specific registers for the CPU
  SIGNAL PC : unsigned(11 DOWNTO 0);
  SIGNAL uPC : unsigned(8 DOWNTO 0); -- unknown 
  SIGNAL IR : unsigned(23 DOWNTO 0);
  SIGNAL ASR : unsigned(1023 DOWNTO 0);
  SIGNAL AR : unsigned(23 DOWNTO 0);

  SIGNAL GRX, GR0, GR1, GR2, GR3, GR4, GR5, GR6, GR7 : unsigned(23 DOWNTO 0);
  -- THe bus!
  SIGNAL data_bus : unsigned(23 DOWNTO 0);

  SIGNAL Z, N, C, V : STD_LOGIC;

BEGIN
  ----------------------
  --- INSTANTIATIONS ---
  ----------------------
  ALU_inst : ENTITY work.ALU_ent
    PORT MAP(
      A => data_bus,
      B => AR,
      op => ALU_op,
      result => ALU_result,
      clk => clk,
      rst => rst,
      flags => (Z, N, C, V)
    );

  uMem_inst : ENTITY work.uMem
    PORT MAP(
      uAddr => uPC,
      uData => micro_instr
    );
  -- Instruction fetch to IR
  fetch_instructions : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst = '1' THEN
        IR <= (OTHERS => '0');
      ELSIF (FB = "100") THEN
        IR <= data_bus;
      END IF;
    END IF;
  END PROCESS;

  -- Instuction Program Counter (PC)
  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (rst = '1') THEN
        PC <= (OTHERS => '0');
      ELSIF (FB = "010") THEN
        PC <= data_bus;
      ELSIF (P = '1') THEN
        PC <= PC + 1;
      END IF;
    END IF;
  END PROCESS;

  -- Intruction micro Program Counter (mPC)
  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst = '1' THEN
        uPC <= (OTHERS => '0');
      ELSIF (SEQ = "0000") THEN
        uPC <= uPC + 1;
      ELSIF (SEQ = "0001") THEN
        uPC <= K1;
      ELSIF (SEQ = "0010") THEN
        uPC <= K2;
      ELSIF (SEQ = "0011") THEN
        uPC <= (OTHERS => '0');
      ELSIF (SEQ = "0100") THEN
        IF (Z = '0') THEN
          uPC <= micro_ADR;
        END IF;
      ELSIF (SEQ = "0101") THEN
        uPC <= micro_ADR;
      ELSIF (SEQ = "0110") THEN
        IF (Z = '1') THEN
          uPC <= micro_ADR;
        END IF;
      ELSIF (SEQ = "0111") THEN
        IF (N = '1') THEN
          uPC <= micro_ADR;
        END IF;
      ELSIF (SEQ = "1000") THEN
        IF (C = '1') THEN
          uPC <= micro_ADR;
        END IF;
      ELSIF (SEQ = "1001") THEN
        IF (C = '0') THEN
          uPC <= micro_ADR;
        END IF;
      ELSE
        -- HALT!!!!!!!!
      END IF;
    END IF;
  END PROCESS;

  -- Instruction to fetch ASR
  ASR_fetch : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst = '1' THEN
        ASR <= (OTHERS => '0');
      ELSIF (FB = "000") THEN
        ASR <= data_bus;
      END IF;
    END IF;
  END PROCESS;
  -- general registers
  GRx <=
    GR0 WHEN (assembly_GRx = "000") ELSE
    GR1 WHEN (assembly_GRx = "001") ELSE
    GR2 WHEN (assembly_GRx = "010") ELSE
    GR3 WHEN (assembly_GRx = "011") ELSE
    GR4 WHEN (assembly_GRx = "100") ELSE
    GR5 WHEN (assembly_GRx = "101") ELSE
    GR6 WHEN (assembly_GRx = "110") ELSE
    GR7 WHEN (assembly_GRx = "111");

  -- the buss(y)
  data_bus <=
    ASR WHEN (TB = "000") ELSE
    assembly_instr WHEN (TB = "001") ELSE
    PC WHEN (TB = "010") ELSE
    ALU_result WHEN (TB = "011") ELSE
    IR WHEN (TB = "100") ELSE
    GRx WHEN (TB = "101") ELSE
    (OTHERS => '0');

END CPU_arch;