--------------------------------------------------------------------------------
-- KBD ENC
-- Version 1.1: 2016-02-16. Anders Nilsson
-- Version 2.0: 2023-01-12. Petter Kallstrom. Changelog: Remove everything that interprets the scancode
-- Description:
-- * Read bytes from a PS2 bus
-- * Encode bytes into scancodes
-- * Limitation: Does not handle scancodes containing "E0" or "E1" bytes.

-- library declaration
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL; -- basic IEEE library
USE IEEE.NUMERIC_STD.ALL; -- IEEE library for the unsigned type
-- and various arithmetic operations

-- entity
ENTITY KBD_ENC IS
	PORT
	(
		clk : IN STD_LOGIC; -- system clock (100 MHz)
		rst : IN STD_LOGIC; -- reset signal
		PS2KeyboardCLK : IN STD_LOGIC; -- USB keyboard PS2 clock
		PS2KeyboardData : IN STD_LOGIC; -- USB keyboard PS2 data
		ScanCode : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- scancode byte
		MAKE_op : OUT STD_LOGIC); -- one-pulsed scancode-enable
END KBD_ENC;

-- architecture
ARCHITECTURE behavioral OF KBD_ENC IS
	SIGNAL PS2Clk : STD_LOGIC; -- Synchronized PS2 clock
	SIGNAL PS2Data : STD_LOGIC; -- Synchronized PS2 data
	SIGNAL PS2Clk_Q1, PS2Clk_Q2 : STD_LOGIC; -- PS2 clock one pulse flip flop
	SIGNAL PS2Clk_op : STD_LOGIC; -- PS2 clock one pulse 

	SIGNAL PS2Data_sr : STD_LOGIC_VECTOR(10 DOWNTO 0);-- PS2 data shift register
	SIGNAL ScanCode_int : STD_LOGIC_VECTOR(7 DOWNTO 0); -- internal version of ScanCode

	SIGNAL PS2BitCounter : unsigned(3 DOWNTO 0); -- PS2 bit counter
	SIGNAL BC11 : STD_LOGIC; -- '1' when PS2BitCounter = 11

	TYPE state_type IS (IDLE, MAKE, BREAK); -- declare state types for PS2
	SIGNAL PS2state : state_type; -- PS2 state

BEGIN

	-- Synchronize PS2-KBD signals
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			PS2Clk <= PS2KeyboardCLK;
			PS2Data <= PS2KeyboardData;
		END IF;
	END PROCESS;

	-- Generate one cycle pulse from PS2 clock, negative edge
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF rst = '1' THEN
				PS2Clk_Q1 <= '1';
				PS2Clk_Q2 <= '0';
			ELSE
				PS2Clk_Q1 <= PS2Clk;
				PS2Clk_Q2 <= NOT PS2Clk_Q1;
			END IF;
		END IF;
	END PROCESS;

	PS2Clk_op <= (NOT PS2Clk_Q1) AND (NOT PS2Clk_Q2);
	-- PS2 data shift register
	PROCESS (clk, rst) BEGIN
		IF (rst = '1') THEN
			PS2Data_sr <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			IF (PS2Clk_op = '1') THEN
				-- Shift in new data to the left
				PS2Data_sr <= PS2Data & PS2Data_sr(PS2Data_sr'left DOWNTO 1);
			END IF;
		END IF;
	END PROCESS;

	ScanCode_int <= PS2Data_sr(8 DOWNTO 1); -- To be used internally
	ScanCode <= ScanCode_int; -- Not allowed to read from out signal

	-- PS2 bit counter
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF rst = '1' THEN
				PS2BitCounter <= (OTHERS => '0');
			ELSIF PS2Clk_op = '1' THEN
				PS2BitCounter <= PS2BitCounter + 1;
			ELSIF PS2BitCounter = 11 THEN
				PS2BitCounter <= to_unsigned(0, 4);
			END IF;
		END IF;
	END PROCESS;
	--
	BC11 <= '1' WHEN PS2BitCounter = 11 ELSE
		'0';

	-- PS2 state
	-- Either MAKE or BREAK state is identified from the scancode
	-- Only single character scan codes are identified
	-- The behavior of multiple character scan codes is undefined

	PROCESS (clk, rst)
	BEGIN
		IF rst = '1' THEN
			PS2state <= IDLE;
		ELSIF rising_edge(clk) THEN
			CASE(PS2state) IS
				WHEN IDLE =>
				IF (BC11 = '1') THEN
					IF (ScanCode_int = x"F0") THEN
						PS2state <= BREAK;
					ELSE
						PS2state <= MAKE;
					END IF;
				END IF;

				WHEN MAKE =>
				PS2state <= IDLE;

				WHEN BREAK =>
				IF (BC11 = '1') THEN
					PS2state <= IDLE;
				END IF;

			END CASE;
		END IF;
	END PROCESS;

	MAKE_op <= '1' WHEN PS2state = MAKE ELSE
		'0';

END behavioral;