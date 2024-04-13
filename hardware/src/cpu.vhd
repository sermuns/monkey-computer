LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
USE std.env.stop;

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
        '1' WHEN FB = "001" ELSE
        '0';

    pMem : ENTITY work.pMem
        PORT MAP(
            rst => rst,
            adress => ASR,
            out_data => PM_out,
            in_data => data_bus,
            should_store => PM_should_store
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
        IF rst = '1' THEN
            uPC <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            CASE SEQ IS
                WHEN "0000" =>
                    -- uPC++
                    uPC <= uPC + 1;
                WHEN "0001" =>
                    -- K1
                    uPC <= K1;
                WHEN "0010" =>
                    -- K2
                    uPC <= K2;
                WHEN "0011" =>
                    -- uPC := 0
                    uPC <= (OTHERS => '0');
                WHEN "0100" =>
                    -- IF Z = 0 => uPC := uADR
                    IF (Z = '0') THEN
                        uPC <= UNSIGNED(uADR);
                    END IF;
                WHEN "0101" =>
                    -- uPC := uADR (BRA)
                    uPC <= UNSIGNED(uADR);
                WHEN "0110" =>
                    -- IF Z = 1 => uPC := uADR
                    IF (Z = '1') THEN
                        uPC <= UNSIGNED(uADR);
                    END IF;
                WHEN "0111" =>
                    -- IF N = 1 => uPC := uADR
                    IF (N = '1') THEN
                        uPC <= UNSIGNED(uADR);
                    END IF;
                WHEN "1000" =>
                    -- IF C = 1 => uPC := uADR
                    IF (C = '1') THEN
                        uPC <= UNSIGNED(uADR);
                    END IF;
                WHEN "1001" =>
                    -- IF C = 0 => uPC := uADR
                    IF (C = '0') THEN
                        uPC <= UNSIGNED(uADR);
                    END IF;
                WHEN "1111" =>
                    REPORT "CPU halting" SEVERITY note;
                    STOP;
                WHEN OTHERS =>
                    REPORT "Unknown SEQ in uMem address " & INTEGER'image(to_integer(uPC)) SEVERITY FAILURE;
            END CASE;
        END IF;
    END PROCESS;

    -- ASSEMBLY / MACRO
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            PC <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF (FB = "010") THEN
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
        IF rst = '1' THEN
            IR <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF (FB = "100") THEN
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
        IF rst = '1' THEN
            ASR <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF (FB = "000") THEN
                ASR <= data_bus(11 DOWNTO 0);
            END IF;
        END IF;
    END PROCESS;

    K1 <=
        b"00001010"/*LOAD.b8*/ WHEN (OP = "00000") ELSE
        b"00001011"/*STORE.b8*/ WHEN (OP = "00001") ELSE
        b"00001100"/*ADD.b8*/ WHEN (OP = "00010") ELSE
        b"00001111"/*SUB.b8*/ WHEN (OP = "00011") ELSE
        b"00011000"/*MUL.b8*/ WHEN (OP = "01111") ELSE
        b"00100101"/*HALT.b8*/ WHEN (OP = "11111") ELSE
        (OTHERS => 'U'); -- something wrong

    K2 <=
        b"00000011"/*DIREKT.b8*/ WHEN (M = "00") ELSE
        b"00000100"/*OMEDELBAR.b8*/ WHEN (M = "01") ELSE
        b"00000110"/*INDIREKT.b8*/ WHEN (M = "10") ELSE
        b"00000111"/*INDEXERAD.b8*/ WHEN (M = "11");

    -- DATA BUS (TO-BUS)
    data_bus <=
        (data_bus'RANGE => '0') + ASR WHEN (TB = "000") ELSE -- Padding + ASR
        unsigned(PM_out) WHEN (TB = "001") ELSE
        (data_bus'RANGE => '0') + PC WHEN (TB = "010") ELSE -- Padding + PC
        AR WHEN (TB = "011") ELSE
        unsigned(IR) WHEN (TB = "100") ELSE
        GRx WHEN (TB = "101") ELSE
        (OTHERS => '-') WHEN (TB = "111") ELSE -- NOOP
        (OTHERS => 'U'); -- something wrong

END ARCHITECTURE;