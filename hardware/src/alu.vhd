LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
ENTITY ALU_ent IS
  PORT (
    data_bus : IN unsigned(23 DOWNTO 0);
    AR : OUT unsigned(23 DOWNTO 0);
    op : IN unsigned(3 DOWNTO 0);

    -- Z, N, C, V
    flags : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    rst : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE ALU_arch OF ALU_ent IS
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

  -- candidate flags
  SIGNAL Zc, Nc, Cc, Vc : STD_LOGIC;

  SIGNAL AR_internal : unsigned(24 DOWNTO 0);
BEGIN
  ALU_proc : PROCESS (OP, data_bus, rst)
  BEGIN
    IF rst = '1' THEN
      AR_internal <= (OTHERS => '0');
    ELSE
      CASE op IS
        WHEN noop_op => NULL;
        WHEN add_op => AR_internal <= AR_internal + ('0' & data_bus);
        WHEN sub_op => AR_internal <= AR_internal - ('0' & data_bus);
        WHEN mul_op => AR_internal <= resize(('0' & data_bus) * AR_internal, AR_internal'length);
        WHEN load_op => AR_internal <= ('0' & data_bus);
        WHEN and_op => AR_internal <= AR_internal AND ('0' & data_bus);
        WHEN or_op => AR_internal <= AR_internal OR ('0' & data_bus);
        WHEN lsr_op => AR_internal <= shift_right(AR, to_integer('0' & data_bus));
        WHEN lsl_op => AR_internal <= shift_left(AR, to_integer('0' & data_bus));
        WHEN cmp_op => NULL; -- what should this do??
        WHEN OTHERS => REPORT "Unknown ALU operation!" & INTEGER'image(to_integer(op)) SEVERITY FAILURE;
      END CASE;
    END IF;
  END PROCESS;

  AR <= AR_internal(23 DOWNTO 0);

  -- all zeroes?
  Zc <=
    '1' WHEN AR = (AR'length - 1 DOWNTO 0 => '0')
    ELSE
    '0';

  -- negative bit set
  Nc <=
    '0';

  -- carry bit gets set when the result of the operation is greater than the maximum value
  Cc <= AR_internal(AR_internal'length - 1);

  Vc <=
    '0';

  status_flags_proc : PROCESS (data_bus, op, rst)
  BEGIN
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
  END PROCESS;
END ARCHITECTURE ALU_arch;