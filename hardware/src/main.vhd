LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;

ENTITY CPU_ent IS
  GENERIC (
    micro_width : INTEGER := 24;
    TB_width : INTEGER := 3;
    FB_width : INTEGER := 3;
    ALU_op_width : INTEGER := 4;
    SEQ_width : INTEGER := 4;
    ADR_width : INTEGER := 9;

    assembly_width : INTEGER := 24;
    OP_width : INTEGER := 4
  );
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC);
END CPU_ent;

-- Architecture definition
ARCHITECTURE CPU_arch OF CPU_ent IS
  COMPONENT uMem

    PORT (
      uAddr : IN unsigned(21 DOWNTO 0);
      uData : OUT unsigned(31 DOWNTO 0));
  END COMPONENT;

  COMPONENT pMem

    PORT (
      pAddr : IN unsigned(21 DOWNTO 0);
      pData : IN unsigned(31 DOWNTO 0));

  END COMPONENT;
  --TODO: HAVE A BIG CONVERSATION ABOUT THESE SIZES :D

  -- Microcode memory
  SIGNAL micro_instr : unsigned(micro_width - 1 DOWNTO 0);
  -- Fields of the microcode instruction
  ALIAS TB : unsigned(TB_width - 1 DOWNTO 0) IS micro_instr(micro_width - 1 DOWNTO micro_width - TB_width);
  ALIAS FB : unsigned(FB_width - 1 DOWNTO 0) IS micro_instr(micro_width - TB_width - 1 DOWNTO micro_width - TB_width - FB_width);
  ALIAS ALU_op : unsigned(ALU_op_width - 1 DOWNTO 0) IS micro_instr(micro_width - TB_width - FB_width - 1 DOWNTO micro_width - TB_width - FB_width - ALU_op_width);
  ALIAS P : STD_LOGIC IS micro_instr(micro_width - TB_width - FB_width - ALU_op_width);
  ALIAS SEQ : unsigned(SEQ_width - 1 DOWNTO 0) IS micro_instr(micro_width - TB_width - FB_width - ALU_op_width - 1 DOWNTO micro_width - TB_width - FB_width - ALU_op_width - SEQ_width);
  ALIAS ADR : unsigned(ADR_width - 1 DOWNTO 0) IS micro_instr(micro_width - TB_width - FB_width - ALU_op_width - SEQ_width - 1 DOWNTO 0);

  -- Main memory: program, heap and stack
  SIGNAL assembly_instr : unsigned (assembly_width - 1 DOWNTO 0);
  -- Field of the assembly instruction
  ALIAS OP : unsigned(OP_width - 1 DOWNTO 0) IS assembly_instr(assembly_width - 1 DOWNTO assembly_width - OP_width);
  -- ?? more fields

  -- Specific registers for the CPU
  SIGNAL PC : unsigned(21 DOWNTO 0);
  SIGNAL uPC : unsigned(8 DOWNTO 0);
  SIGNAL IR : unsigned(21 DOWNTO 0);
  SIGNAL ASR : unsigned(11 DOWNTO 0);

  -- THe bus!
  SIGNAL DATA_BUS : unsigned(23 DOWNTO 0);
BEGIN

  -- Arithmetic Logic Unit
  ALU_inst : ENTITY work.ALU_ent
    PORT MAP
    (
      data_bus => DATA_BUS,
      ALU_op => ALU_op
    );

END CPU_arch;