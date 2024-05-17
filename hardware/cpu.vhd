LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
USE std.env.stop;

ENTITY cpu IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        ScanCode : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        make_op : IN  STD_LOGIC;
        v_addr : IN unsigned(7 DOWNTO 0);
        v_data : OUT unsigned(5 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE func OF cpu IS
    -- ASSEMBLY / MACRO
    SIGNAL PC : unsigned(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PM_out : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL PM_we : STD_LOGIC;

    -- Instruction register
    SIGNAL IR : STD_LOGIC_VECTOR (23 DOWNTO 0);
    -- Field of the assembly instruction
    ALIAS OP IS IR(23 DOWNTO 19);
    ALIAS GRx_num IS IR(18 DOWNTO 15);
    ALIAS M IS IR(14 DOWNTO 13);
    alias KEY is IR(12);
    ALIAS ADR IS IR(11 DOWNTO 0);

    
    -- MICRO
    SIGNAL uPC : unsigned(7 DOWNTO 0);
    SIGNAL uPM : STD_LOGIC_VECTOR(24 DOWNTO 0);
    ALIAS TB IS uPM(24 DOWNTO 22);
    ALIAS FB IS uPM(21 DOWNTO 19);
    ALIAS ALU_op IS uPM(18 DOWNTO 15);
    ALIAS P IS uPM(14);
    ALIAS SP_op IS uPM(13 DOWNTO 12);
    ALIAS SEQ IS uPM(11 DOWNTO 8);
    ALIAS uADR IS uPM(7 DOWNTO 0);

    SIGNAL K1, K2 : unsigned(7 DOWNTO 0);

    SIGNAL data_bus : unsigned(23 DOWNTO 0);
    -- GENERAL REGISTERS
    TYPE GR_t IS ARRAY(0 TO 15) OF unsigned(23 DOWNTO 0);
    SIGNAL GR : GR_t;

    SIGNAL GRx : unsigned(23 DOWNTO 0);

    SIGNAL ASR : unsigned(11 DOWNTO 0);

    -- ALU
    SIGNAL AR : unsigned(23 DOWNTO 0);

    SIGNAL SP : UNSIGNED(11 DOWNTO 0) := b"111111111111"; -- Bottom of the PM
    
    
    COMPONENT alu IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;

            data_bus : IN unsigned(23 DOWNTO 0);
            AR : OUT unsigned(23 DOWNTO 0);
            op : IN unsigned(3 DOWNTO 0);

            -- flags
            Z, N, C, V : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL Z, N, C, V : STD_LOGIC;

    COMPONENT pMem IS
        PORT (
            clk : IN STD_LOGIC;
            rst: IN STD_LOGIC;
            cpu_address : IN unsigned(11 DOWNTO 0);
            cpu_data_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
            cpu_data_in : IN unsigned(23 DOWNTO 0);
            cpu_we : IN STD_LOGIC;
            video_address : IN unsigned(7 DOWNTO 0);
            video_data_out : OUT unsigned(5 DOWNTO 0));
    END COMPONENT;

    COMPONENT uMem IS
        PORT (
            address : IN unsigned(7 DOWNTO 0);
            data : OUT STD_LOGIC_VECTOR(24 DOWNTO 0)
        );
    END COMPONENT;

BEGIN

    -- MICRO TICKING
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            uPC <= (others => '0');
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
                    -- IF Z = 0 => uPC := uADR (BNE)
                    uPC <= UNSIGNED(uADR) WHEN (Z = '0') ELSE uPC + 1;
                WHEN "0101" =>
                    -- uPC := uADR (BRA)
                    uPC <= UNSIGNED(uADR);
                WHEN "0110" =>
                    -- IF Z = 1 => uPC := uADR (BEQ)
                    uPC <= UNSIGNED(uADR) WHEN (Z = '1') ELSE uPC + 1;
                WHEN "0111" =>
                    -- IF N = 1 => uPC := uADR
                    uPC <= UNSIGNED(uADR) WHEN (N = '1') ELSE uPC + 1;
                WHEN "1000" =>
                    -- IF C = 1 => uPC := uADR
                    uPC <= UNSIGNED(uADR) WHEN (C = '1') ELSE uPC + 1;
                WHEN "1001" =>
                    -- IF C = 0 => uPC := uADR
                    uPC <= UNSIGNED(uADR) WHEN (C = '0') ELSE uPC + 1;
                WHEN "1111" =>
                    REPORT "CPU gracefully halting :)";
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
            PC <= to_unsigned(0, PC'length);
        ELSIF rising_edge(clk) THEN
            IF (FB = "010") THEN
                PC <= data_bus(PC'length-1 DOWNTO 0);
            ELSIF (P = '1') THEN
                PC <= PC + 1;
            END IF;
        END IF;
    END PROCESS;

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
    GRx <= GR(3) when (M="11" and uPC < 15) else
        GR(TO_INTEGER(unsigned(GRx_num)));
    
        
    process (clk, rst)
    begin
        if rst = '1' then
            GR <= (Others => (OTHERS => '0'));
        elsif rising_edge(clk) then
            if (FB = "101") then
                GR(TO_INTEGER(unsigned(GRx_num))) <= data_bus;
            else
                case ScanCode is
                    when x"1C" => GR(15) <= b"0000000000000000000_00001"; -- A (left)
                    when x"23" => GR(15) <= b"0000000000000000000_00010"; -- D (right)
                    when x"1D" => GR(15) <= b"0000000000000000000_00100"; -- W (up)
                    when x"1B" => GR(15) <= b"0000000000000000000_01000"; -- S (down)
                    when x"29" => GR(15) <= b"0000000000000000000_00011"; -- Space (confirm)
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- ASR
    PROCESS (clk, rst)
    BEGIN
          IF rst = '1' THEN
            ASR <= (OTHERS => '0');
          ELSIF rising_edge(clk) THEN
            IF (FB = "000") THEN
                ASR <= data_bus(ASR'length - 1 DOWNTO 0);
            END IF;
        END IF;
    END PROCESS;

    -- SP
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            SP <= b"111111111111";
            ELSIF rising_edge(clk) THEN
            IF SP_op = "01" THEN
                SP <= SP - 1;
                ELSIF SP_op = "10" AND (SP /= b"111111111111111") THEN
                SP <= SP + 1;
            END IF;
        END IF;
    END PROCESS;

    K1 <=
    b"00001111"/*LOAD.b8*/ WHEN (OP = "00000") ELSE
    b"00010001"/*STORE.b8*/ WHEN (OP = "00001") ELSE
    b"00010011"/*ADD.b8*/ WHEN (OP = "00010") ELSE
    b"00010110"/*SUB.b8*/ WHEN (OP = "00011") ELSE
    b"00011001"/*CMP.b8*/ WHEN (OP = "00100") ELSE
    b"00011011"/*AND.b8*/ WHEN (OP = "00101") ELSE
    b"00100011"/*OR.b8*/ WHEN (OP = "00110") ELSE
    b"00011110"/*LSR.b8*/ WHEN (OP = "00111") ELSE
    b"00101100"/*JSR.b8*/ WHEN (OP = "01001") ELSE
    b"00100110"/*BRA.b8*/ WHEN (OP = "01010") ELSE
    b"00101000"/*BNE.b8*/ WHEN (OP = "01011") ELSE
    b"00101010"/*BEQ.b8*/ WHEN (OP = "01100") ELSE
    b"00101111"/*PUSH.b8*/ WHEN (OP = "01101") ELSE
    b"00110001"/*POP.b8*/ WHEN (OP = "01110") ELSE
    b"00100000"/*MUL.b8*/ WHEN (OP = "01111") ELSE
    b"00110101"/*RET.b8*/ WHEN (OP = "10000") ELSE
    b"00111001"/*MOV.b8*/ when (OP = "10010") else
    b"00111011"/*SWAP.b8*/ when (OP = "10001") else
    b"01000100"/*HALT.b8*/ WHEN (OP = "11111") ELSE
    (OTHERS => 'U'); -- something wrong

    K2 <=
    b"00000101"/*DIREKT.b8*/ WHEN (M = "00" OR M = "--") ELSE
    b"00000111"/*OMEDELBAR.b8*/ WHEN (M = "01") ELSE
    b"00001001"/*INDIREKT.b8*/ WHEN (M = "10") ELSE
    b"00001011"/*INDEXERAD.b8*/ WHEN (M = "11") ELSE
    (OTHERS => 'U'); -- something wrong

    -- DATA BUS
    data_bus <=
        resize(ASR, data_bus'LENGTH) WHEN (TB = "000") ELSE -- Resize ASR
        resize(unsigned(PM_out), data_bus'LENGTH) WHEN (TB = "001") ELSE
        resize(PC, data_bus'LENGTH) WHEN (TB = "010") ELSE -- Resize PC
        resize(AR, data_bus'LENGTH) WHEN (TB = "011") ELSE
        resize(unsigned(IR(11 DOWNTO 0)), data_bus'LENGTH) WHEN (TB = "100") ELSE
        resize(SP, data_bus'LENGTH) WHEN (TB = "110") ELSE -- Resize SP
        resize(GRx, data_bus'LENGTH) WHEN (TB = "101") ELSE
        (OTHERS => '-') WHEN (TB = "111") ELSE -- NOOP
        (OTHERS => 'U'); -- something wrong


    -- ALU
    ALU_inst : alu
    PORT MAP(
        clk => clk,
        data_bus => data_bus,
        AR => AR,
        op => unsigned(ALU_op),
        rst => rst,
        Z => Z,
        N => N,
        C => C,
        V => V
    );

    -- PROGRAM MEMORY
    PM_we <= '1' WHEN (FB = "001") ELSE '0';

    pMem_inst : pMem
    PORT MAP(
        clk => clk,
        rst => rst,
        cpu_address => ASR,
        cpu_data_out => PM_out,
        cpu_data_in => data_bus,
        cpu_we => PM_we,
        video_address => v_addr,
        video_data_out => v_data
    );

    -- MICRO MEMORY
    uMem_inst : uMem
    PORT MAP(
        address => uPC,
        data => uPM
    );
END ARCHITECTURE;