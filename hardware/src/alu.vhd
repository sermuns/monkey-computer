LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
ENTITY ALU_ent IS
  PORT (
    data_bus : IN unsigned(23 DOWNTO 0);
    AR : BUFFER unsigned(23 DOWNTO 0);
    op : IN unsigned(3 DOWNTO 0);
    -- result : BUFFER unsigned(23 DOWNTO 0) := (OTHERS => '0');

    -- Z, N, C, V
    flags : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE ALU_arch OF ALU_ent IS
  CONSTANT noop_op : unsigned(3 DOWNTO 0) := "0000";
  CONSTANT add_op : unsigned(3 DOWNTO 0) := "0001";
  CONSTANT sub_op : unsigned(3 DOWNTO 0) := "0010";
  CONSTANT mul_op : unsigned(3 DOWNTO 0) := "0011";
  CONSTANT load_op : unsigned(3 DOWNTO 0) := "0100";

  -- candidate flags
  SIGNAL Zc, Nc, Cc, Vc : STD_LOGIC;

BEGIN
  ALU_proc : PROCESS (clk)
  BEGIN
    IF rst = '1' THEN
      AR <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      CASE op IS
        WHEN add_op => AR <= AR + data_bus; -- addition
        WHEN sub_op => AR <= AR - data_bus; -- subtraction
        WHEN mul_op => AR <= resize(data_bus * AR, AR'length);
        WHEN load_op => AR <= data_bus; -- load, R := B
        WHEN OTHERS => NULL;
      END CASE;
    END IF;
    -- AND and other bit manipp
    -- ska den en biljard ggr i nanosekunden??
  END PROCESS;

  -- all zeroes?
  Zc <=
    '1' WHEN AR = (AR'length - 1 DOWNTO 0 => '0')
    ELSE
    '0';

  -- -- negative bit set
  -- Nc <=
  --   result(result'high);

  -- -- carry out?
  -- Cc <=
  --   result(result'high);

  status_flags_proc : PROCESS (clk)
  BEGIN
    IF (rst = '1') THEN
      flags <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      CASE op IS
        WHEN add_op | sub_op =>
          flags <= Zc & Nc & Cc & Vc;
        WHEN mul_op =>
          flags <= Zc & Nc & Cc & flags(3);
        WHEN OTHERS => NULL;
      END CASE;
    END IF;
  END PROCESS;
END ARCHITECTURE ALU_arch;