LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pMem IS
    PORT (
        clk : IN STD_LOGIC;
        cpu_address : IN unsigned(11 DOWNTO 0);
        cpu_data_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        cpu_data_in : IN unsigned(23 DOWNTO 0);
        cpu_we : IN STD_LOGIC;
        video_address : IN unsigned(7 DOWNTO 0);
        video_data_out : OUT unsigned(5 DOWNTO 0)
    );
END pMem;

ARCHITECTURE func OF pMem IS


    TYPE p_mem_type IS ARRAY(0 TO 4095) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    CONSTANT PROGRAM : INTEGER := 0;
    CONSTANT VMEM : INTEGER := 1500;
    CONSTANT PATH : INTEGER := 1630;

    SIGNAL p_mem : p_mem_type := (
        -- Your initialization values here
        OTHERS => (OTHERS => '-')
    );

BEGIN

    -- Reading from two-port ram
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            cpu_data_out <= p_mem(TO_INTEGER(cpu_address) + PROGRAM);
            video_data_out <= unsigned(p_mem(TO_INTEGER(video_address) + VMEM)(5 DOWNTO 0));
        END IF;
    END PROCESS;

    -- STORE
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (cpu_we = '1') THEN
                p_mem(TO_INTEGER(cpu_address)) <= STD_LOGIC_VECTOR(cpu_data_in);
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;