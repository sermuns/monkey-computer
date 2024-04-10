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
    SIGNAL PM_out : STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- Instruction register
    SIGNAL IR : STD_LOGIC_VECTOR (23 DOWNTO 0);
    -- Field of the assembly instruction
    ALIAS OP IS IR(23 DOWNTO 19);
    ALIAS GRx_num IS IR(18 DOWNTO 16);
    ALIAS M IS IR(15 DOWNTO 14);
    ALIAS ADR IS IR(11 DOWNTO 0);

    -- MICRO
    SIGNAL uPC : unsigned(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL uPM : STD_LOGIC_VECTOR(22 DOWNTO 0);
    ALIAS TB IS uPM(22 DOWNTO 20);
    ALIAS FB IS uPM(19 DOWNTO 17);
    ALIAS ALU_op IS uPM(16 DOWNTO 13);
    ALIAS P IS uPM(12);
    ALIAS SEQ IS uPM(11 DOWNTO 8);
    ALIAS uADR IS uPM(7 DOWNTO 0);

    SIGNAL PM_should_store : STD_LOGIC;
    SIGNAL PM_in : unsigned(23 DOWNTO 0);

    SIGNAL K1, K2 : unsigned(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL data_bus : unsigned(23 DOWNTO 0) := (OTHERS => '0');

    -- GENERAL REGISTERS
    TYPE GR_t IS ARRAY(0 TO 7) OF unsigned(23 DOWNTO 0);
    SIGNAL GR : GR_t := (OTHERS => (OTHERS => '0'));

    SIGNAL GRx : unsigned(23 DOWNTO 0);

    SIGNAL ASR : unsigned(11 DOWNTO 0) := (OTHERS => '0');

    -- ALU
    SIGNAL AR : unsigned(23 DOWNTO 0) := (OTHERS => '0');

    SIGNAL flags : STD_LOGIC_VECTOR(3 DOWNTO 0);
    ALIAS Z IS flags(0);
    ALIAS N IS flags(1);
    ALIAS C IS flags(2);
    ALIAS V IS flags(3);

    SIGNAL SP : UNSIGNED(11 DOWNTO 0) := b"000000000000";
BEGIN

    -- PROGRAM MEMORY
    PM_should_store <=
        '1' WHEN FB = "001" AND OP = "00001"
        ELSE
        '0';
    pMem : ENTITY work.pMem
        PORT MAP(
            rst => rst,
            adress => ASR,
            out_data => PM_out,
            in_data => PM_in,
            should_store => PM_should_store
        );

    PM_in <=
        data_bus WHEN (FB = "001") ELSE
        (OTHERS => '-');

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
            ELSIF (SEQ = "1111") THEN
                NULL;
            ELSE
                REPORT "Unknown SEQ in uMem adress " & INTEGER'image(to_integer(uPC)) SEVERITY FAILURE;
            END IF;
        END IF;
    END PROCESS;

    -- ASSEMBLY / MACRO
    PROCESS (clk, rst)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                PC <= (OTHERS => '0');
            ELSIF (FB = "010") THEN
                PC <= unsigned(data_bus);
            ELSIF (P = '1') THEN
                PC <= PC + 1;
            END IF;
        END IF;
    END PROCESS;

    -- ALU
    ALU_inst : ENTITY work.ALU_ent
        PORT MAP(
            data_bus => data_bus,
            AR => AR,
            op => unsigned(ALU_op),
            clk => clk,
            rst => rst,
            flags => flags
        );

    -- INSTRUCTION REGISTER
    PROCESS (clk, rst)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                IR <= (OTHERS => '0');
            ELSIF (FB = "100") THEN
                IR <= STD_LOGIC_VECTOR(data_bus);
            END IF;
        END IF;
    END PROCESS;

    -- GENERAL REGISTERS (GRx) 
    GRx <= GR(TO_INTEGER(unsigned(GRx_num)));
    GR(TO_INTEGER(unsigned(GRx_num))) <= data_bus WHEN (FB = "101");

    -- ASR
    PROCESS (clk, rst)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                ASR <= (OTHERS => '0');
            ELSIF (FB = "000") THEN
                ASR <= data_bus(11 DOWNTO 0);
            END IF;
        END IF;
    END PROCESS;

    K1 <=
        -- LOAD
        "00001010" WHEN (OP = "00000") ELSE
        -- STORE 
        "00001011" WHEN (OP = "00001") ELSE
        -- ADD
        "00001100" WHEN (OP = "00010") ELSE
        -- SUB
        "00001111" WHEN (OP = "00011") ELSE
        -- MUL
        "00011000" WHEN (OP = "01111") ELSE
        -- HALT
        "00010011" WHEN (OP = "11111") ELSE

        (OTHERS => 'U'); -- something wrong

    K2 <=
        "00000011" WHEN (M = "00") ELSE -- Absolut
        "00000100" WHEN (M = "01") ELSE -- Omedelbar
        "00000110" WHEN (M = "10") ELSE -- Indirekt
        "00000111" WHEN (M = "11") ELSE -- Indexerad
        (OTHERS => 'U');

    -- DATA BUS (TO-BUS)
    data_bus <=
        (data_bus'RANGE => '0') + ASR WHEN (TB = "000") ELSE -- Padding + ASR
        unsigned(PM_out) WHEN (TB = "001") ELSE
        (data_bus'RANGE => '0') + PC WHEN (TB = "010") ELSE -- Padding + PC
        AR WHEN (TB = "011") ELSE
        unsigned(IR) WHEN (TB = "100") ELSE
        GRx WHEN (TB = "101") ELSE
        (OTHERS => 'U');

END ARCHITECTURE;