LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
ENTITY alu IS
  PORT
  (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;

    data_bus : IN unsigned(23 DOWNTO 0);
    AR : OUT unsigned(23 DOWNTO 0);
    op : IN unsigned(3 DOWNTO 0);

    -- flags
    Z, N, C, V : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE func OF alu IS
  CONSTANT noop_op : unsigned(3 DOWNTO 0) := "0000";
  CONSTANT add_op : unsigned(3 DOWNTO 0) := "0001";
  CONSTANT sub_op : unsigned(3 DOWNTO 0) := "0010";
  CONSTANT mul_op : unsigned(3 DOWNTO 0) := "0011";
  CONSTANT load_op : unsigned(3 DOWNTO 0) := "0100";
  CONSTANT and_op : unsigned(3 DOWNTO 0) := "0101";
  CONSTANT or_op : unsigned(3 DOWNTO 0) := "0110";
  CONSTANT lsr_op : unsigned(3 DOWNTO 0) := "0111";
  CONSTANT lsl_op : unsigned(3 DOWNTO 0) := "1000";
  CONSTANT cmp_op : unsigned(3 DOWNTO 0) := "1001";
  CONSTANT dont_care : unsigned(3 DOWNTO 0) := "----";

  -- candidate flags
  SIGNAL Zc, Nc, Cc, Vc : STD_LOGIC;

  SIGNAL AR_internal : unsigned(24 DOWNTO 0);
BEGIN
  ALU_proc : PROCESS (clk)
  BEGIN
    IF rst = '1' THEN
      AR_internal <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      CASE op IS
        WHEN noop_op | dont_care => NULL;
        WHEN add_op => AR_internal <= AR_internal + resize(data_bus, AR_internal'length);
        WHEN sub_op | cmp_op => AR_internal <= AR_internal - resize(data_bus, AR_internal'length);
        WHEN mul_op => AR_internal <= resize(('0' & data_bus) * AR_internal, AR_internal'length);
        WHEN load_op => AR_internal <= resize(data_bus, AR_internal'length);
        WHEN and_op => AR_internal <= AR_internal AND ('0' & data_bus);
        WHEN or_op => AR_internal <= AR_internal OR ('0' & data_bus);
        WHEN lsr_op => AR_internal <= shift_right(AR_internal, to_integer('0' & data_bus));
        WHEN lsl_op => AR_internal <= shift_left(AR_internal, to_integer('0' & data_bus));
        WHEN OTHERS => REPORT "Unknown ALU operation!" & INTEGER'image(to_integer(op)) SEVERITY FAILURE;
      END CASE;
    END IF;
  END PROCESS;

  AR <= AR_internal(AR'length - 1 DOWNTO 0);

  Z <= '1' WHEN AR_internal = to_unsigned(0, AR_internal'length) ELSE '0';
  N <= '1' WHEN AR_internal(AR_internal'length - 2) = '1' ELSE '0';
  C <= AR_internal(AR_internal'left);
  V <= '1' WHEN AR_internal(AR_internal'length - 1) = '1' ELSE '0';

  -- -- only assign `out` flags under certain conditions
  -- status_flags_proc : PROCESS (clk, rst)
  -- BEGIN
  --   IF (rst = '1') THEN
  --     Z <= '0';
  --     N <= '0';
  --     C <= '0';
  --     V <= '0';
  --   ELSIF rising_edge(clk) THEN
  --     CASE op IS
  --       WHEN cmp_op | sub_op | add_op =>
  --         Z <= '1' WHEN AR_internal = to_unsigned(0, AR_internal'length) ELSE '0';
  --         N <= '1' WHEN AR_internal(AR_internal'length - 2) = '1' ELSE '0';
  --         C <= AR_internal(AR_internal'left);
  --         V <= '1' WHEN AR_internal(AR_internal'length - 1) = '1' ELSE '0';
  --       WHEN OTHERS =>
  --         NULL;
  --     END CASE;
  --   END IF;
  -- END PROCESS;
END ARCHITECTURE;