LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;

ENTITY cpu IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC
    );
END ENTITY;

ARCHITECTURE func OF cpu IS
    -- ASSEMBLY / MACRO
    SIGNAL PC : unsigned(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PM : STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- Instruction register
    SIGNAL IR : STD_LOGIC_VECTOR (23 DOWNTO 0); -- EX. "00000_000_00_0000000000000" => "OP_GRx_M_ADR"
    -- Field of the assembly instruction
    ALIAS OP : STD_LOGIC_VECTOR(4 DOWNTO 0) IS IR(23 DOWNTO 19);
    ALIAS GRx : STD_LOGIC_VECTOR(2 DOWNTO 0) IS IR(18 DOWNTO 16);
    ALIAS M : STD_LOGIC_VECTOR(1 DOWNTO 0) IS IR(15 DOWNTO 14);
    ALIAS ADR : STD_LOGIC_VECTOR(11 DOWNTO 0) IS IR(13 DOWNTO 2);

    -- MICRO
    SIGNAL uPC : unsigned(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL uPM : STD_LOGIC_VECTOR(22 DOWNTO 0);
    ALIAS TB : STD_LOGIC_VECTOR(2 DOWNTO 0) IS uPM(22 DOWNTO 20);
    ALIAS FB : STD_LOGIC_VECTOR(2 DOWNTO 0) IS uPM(19 DOWNTO 17);
    ALIAS ALU_op : STD_LOGIC_VECTOR(3 DOWNTO 0) IS uPM(16 DOWNTO 13);
    ALIAS P : STD_LOGIC IS uPM(12);
    ALIAS SEQ : STD_LOGIC_VECTOR(3 DOWNTO 0) IS uPM(11 DOWNTO 8);
    ALIAS uADR : STD_LOGIC_VECTOR(7 DOWNTO 0) IS uPM(7 DOWNTO 0);

    SIGNAL K1, K2 : unsigned(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL data_bus : STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- ALU
    SIGNAL Z, N, C, V : STD_LOGIC;
BEGIN
    -- PROGRAM MEMORY
    pMem : ENTITY work.pMem
        PORT MAP(
            adress => PC,
            data => PM
        );
    -- MICRO MEMORY
    uMem : ENTITY work.uMem
        PORT MAP(
            address => uPC,
            data => uPM
        );

    -- MICRO TICKING
    PROCESS (clk, rst)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                uPC <= (OTHERS => '0');
            ELSIF (SEQ = "0000") THEN
                -- uPC++
                uPC <= uPC + 1;
            ELSIF (SEQ = "0001") THEN
                -- K1
                uPC <= K1;
            ELSIF (SEQ = "0010") THEN
                -- K2
                uPC <= K2;
            ELSIF (SEQ = "0011") THEN
                -- uPC := 0
                uPC <= (OTHERS => '0');
            ELSIF (SEQ = "0100") THEN
                -- IF Z = 0 => uPC := uADR
                IF (Z = '0') THEN
                    uPC <= UNSIGNED(uADR);
                END IF;
            ELSIF (SEQ = "0101") THEN
                -- uPC := uADR (BRA)
                uPC <= UNSIGNED(uADR);
            ELSIF (SEQ = "0110") THEN
                -- IF Z = 1 => uPC := uADR
                IF (Z = '1') THEN
                    uPC <= UNSIGNED(uADR);
                END IF;
            ELSIF (SEQ = "0111") THEN
                -- IF N = 1 => uPC := uADR
                IF (N = '1') THEN
                    uPC <= UNSIGNED(uADR);
                END IF;
            ELSIF (SEQ = "1000") THEN
                -- IF C = 1 => uPC := uADR
                IF (C = '1') THEN
                    uPC <= UNSIGNED(uADR);
                END IF;
            ELSIF (SEQ = "1001") THEN
                -- IF C = 0 => uPC := uADR
                IF (C = '0') THEN
                    uPC <= UNSIGNED(uADR);
                END IF;
            ELSE
                REPORT "Unknown SEQ in uMem adress " & INTEGER'image(to_integer(uPC)) SEVERITY FAILURE;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;