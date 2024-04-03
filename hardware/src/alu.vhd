LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;

ENTITY ALU_ent IS
  PORT (
    FB_val : IN unsigned(11 DOWNTO 0);
    val : OUT unsigned(11 DOWNTO 0);
    operation : IN unsigned(3 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE ALU_arch OF ALU_ent IS
BEGIN
  --And?
  --Shifts?
  PROCESS (operation, FB_val)
  BEGIN
    WITH operation SELECT val <=
      FB_val WHEN "0000",
      val + FB_val WHEN "0001",
      val - FB_val WHEN "0010",
      val * FB_val WHEN "0011",
      (OTHERS => '0') WHEN OTHERS;
  END PROCESS;

END ARCHITECTURE ALU_arch;