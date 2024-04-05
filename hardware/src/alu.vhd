LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
ENTITY ALU_ent IS
  PORT (
    A : BUFFER unsigned(23 DOWNTO 0) := (OTHERS => '0');
    B : BUFFER unsigned(23 DOWNTO 0) := (OTHERS => '0');
    op : IN unsigned(3 DOWNTO 0);
    result : BUFFER unsigned(23 DOWNTO 0) := (OTHERS => '0');

    -- Z, N, C, V
    flags : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');

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
  ALU_proc : PROCESS (A, B, op)
  BEGIN
    -- AND and other bit manipp
    -- ska den en biljard ggr i nanosekunden??
    CASE op IS
      WHEN noop_op => result <= (OTHERS => '0'); -- noop, R := 0
      WHEN add_op => result <= A + B; -- addition
      WHEN sub_op => result <= A - B; -- subtraction
      WHEN mul_op => result <= resize(A * B, result'length);
      WHEN load_op => result <= B; -- load, R := B
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;

  -- all zeroes?
  Zc <=
    '1' WHEN result = (result'length - 1 DOWNTO 0 => '0')
    ELSE
    '0';

  -- negative bit set
  Nc <=
    result(result'high);

  -- carry out?
  Cc <=
    result(result'high);

  status_flags_proc : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (rst = '1') THEN
        flags <= (OTHERS => '0');
      ELSE
        CASE op IS
          WHEN add_op | sub_op =>
            flags <= Zc & Nc & Cc & Vc;
          WHEN mul_op =>
            flags <= Zc & Nc & Cc & flags(3);
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE ALU_arch;