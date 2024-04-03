LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;

ENTITY ALU_ent IS
  PORT (
    data_bus : IN unsigned(23 DOWNTO 0);
    AR_out : OUT unsigned(23 DOWNTO 0);
    operation : IN unsigned(3 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE ALU_arch OF ALU_ent IS
  SIGNAL AR : unsigned(11 DOWNTO 0);
BEGIN
  WITH operation SELECT AR_out <=
    data_bus WHEN "0000",
    AR + data_bus WHEN "0001",
    AR - data_bus WHEN "0010",
    AR * data_bus WHEN "0011",
    (OTHERS => '0') WHEN OTHERS;
END ARCHITECTURE ALU_arch;