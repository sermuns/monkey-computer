LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
ENTITY ALU_ent IS
  PORT (
    A : IN unsigned(23 DOWNTO 0);
    ALU_op : IN unsigned(3 DOWNTO 0);
    result : OUT unsigned(23 DOWNTO 0) := (OTHERS => '0');
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    Z, N, C, V : OUT STD_LOGIC := '0' -- status flags, initially all 0
  );
END ENTITY;

ARCHITECTURE ALU_arch OF ALU_ent IS
  SIGNAL result_internal : unsigned(11 DOWNTO 0);
  CONSTANT noop_op : unsigned(3 DOWNTO 0) := "0000";
  CONSTANT add_op : unsigned(3 DOWNTO 0) := "0001";
  CONSTANT sub_op : unsigned(3 DOWNTO 0) := "0010";
  CONSTANT mul_op : unsigned(3 DOWNTO 0) := "0011";

  SIGNAL Zc, Nc, Cc, Vc : STD_LOGIC; -- candidate flags
BEGIN
  ALU_proc : PROCESS (result_internal, A, ALU_op)
  BEGIN
    -- AND and other bit manipp
    -- ska den en biljard ggr i nanosekunden??
    CASE ALU_op IS
      WHEN noop_op => result <= (OTHERS => '0'); -- noop, R := 0
      WHEN add_op => result <= result_internal + A; -- addition
      WHEN sub_op => result <= result_internal - A; -- subtraction
      WHEN mul_op => result <= result_internal * A; -- unsigned muls
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;

  --Nc Vc Zc Cc
  Vc <= (NOT result_internal(3) AND NOT A(3) AND result(3)) OR
    (result_internal(3) AND A(3) AND NOT result_internal(3)) WHEN (ALU_op = add_op) ELSE
    (NOT result_internal(3) AND A(3) AND result(3)) OR
    (result_internal(3) AND NOT A(3) AND NOT result(3)) WHEN (ALU_op = sub_op) ELSE
    '0';
  -- Nc <= result_internal(23) when ALU_op = mul_op else 

  status_flags_proc : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (rst = '1') THEN
        Z <= '0';
        N <= '0';
        C <= '0';
        V <= '0';
      ELSE
        CASE ALU_op IS
          WHEN noop_op => NULL;
          WHEN add_op | sub_op => 
            Z <= Zc;
            N <= Nc;
            C <= Cc;
            V <= Vc;
          WHEN mul_op => 
            Z <= Zc;
            N <= Nc;
            C <= Cc;
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE ALU_arch;