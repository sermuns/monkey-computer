LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
ENTITY CPU IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC);
END CPU;

-- Architecture definition
ARCHITECTURE CPU_arch OF CPU IS
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
  -- Signals for microcode memory
  SIGNAL MicroInstruction : unsigned(23 DOWNTO 0);
  ALIAS TB : unsigned(2 DOWNTO 0) IS MicroInstruction(23 DOWNTO 21);
  ALIAS FB : unsigned(2 DOWNTO 0) IS MicroInstruction(20 DOWNTO 18);
  ALIAS ALU_op : unsigned(3 DOWNTO 0) IS MicroInstruction(17 DOWNTO 14);
  ALIAS P : STD_LOGIC IS MicroInstruction(13);
  ALIAS SEQ : unsigned(3 DOWNTO 0) IS MicroInstruction(12 DOWNTO 9);
  ALIAS ADR : unsigned(8 DOWNTO 0) IS MicroInstruction(8 DOWNTO 0);

  -- Signals for program memory currently 22 bits 
  SIGNAL PM : unsigned (21 DOWNTO 0);

  SIGNAL PC : unsigned(21 DOWNTO 0);
  SIGNAL uPC : unsigned(8 DOWNTO 0);
  SIGNAL IR : unsigned(21 DOWNTO 0);
  SIGNAL ASR : unsigned(11 DOWNTO 0);

  SIGNAL DATA_BUS : unsigned(23 DOWNTO 0);
BEGIN

  ALU_inst : ENTITY work.ALU_ent
    PORT MAP
    (
      data_bus => DATA_BUS,
      operation => ALU_op
    );

END CPU_arch;