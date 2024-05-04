LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.stop;

ENTITY test_tb IS
END ENTITY;

ARCHITECTURE testbench OF test_tb IS
    -- Constants
    CONSTANT CLK_PERIOD : TIME := 10 ns;
    CONSTANT MAX_CLK_COUNT : NATURAL := 1e6;

    -- TB Signals
    SIGNAL clk_tb : STD_LOGIC := '0';
    SIGNAL rst_tb : STD_LOGIC := '1';
    SIGNAL clock_count_tb : NATURAL := 0;
BEGIN
    -- Clock process
    clk_process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        clk_tb <= NOT clk_tb;
    END PROCESS;

    clk_counter : PROCESS
    BEGIN
        WAIT UNTIL rising_edge(clk_tb);
        clock_count_tb <= clock_count_tb + 1; -- rising edge => increment clock count

        IF clock_count_tb > MAX_CLK_COUNT THEN
            REPORT "Simulation has continued for longer than MAX_CLK_COUNT, stopping";
            stop;
        END IF;
    END PROCESS;

    rst_proc : PROCESS
    BEGIN
        -- reset
        WAIT FOR CLK_PERIOD * 1.25;
        rst_tb <= '0';
        WAIT;
    END PROCESS;

END ARCHITECTURE;
