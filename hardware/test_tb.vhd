LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.stop;

ENTITY test_tb IS
END ENTITY;

ARCHITECTURE testbench OF test_tb IS
    -- Constants
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals
    SIGNAL clk_tb : STD_LOGIC := '0';
    SIGNAL rst_tb : STD_LOGIC := '1';

    SIGNAL clock_count_tb : NATURAL := 0;
    CONSTANT MAX_CLK_COUNT : NATURAL := 1e2;

    SIGNAL x : unsigned(3 DOWNTO 0);
    SIGNAL y : unsigned(3 DOWNTO 0);
    SIGNAL x_comb : unsigned(3 DOWNTO 0);

BEGIN
    -- Clock process
    clk_process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        clk_tb <= NOT clk_tb;

        IF now > CLK_PERIOD * MAX_CLK_COUNT THEN
            REPORT "Simulation has continued for longer than MAX_CLK_COUNT, stopping";
            stop;
        END IF;
    END PROCESS;

    clk_counter : PROCESS
    BEGIN
        WAIT UNTIL rising_edge(clk_tb);
        clock_count_tb <= clock_count_tb + 1; -- rising edge => increment clock count
    END PROCESS;

    -- Stimulus process
    stimulus_process : PROCESS
    BEGIN
        -- reset
        WAIT FOR CLK_PERIOD * 1.25;
        rst_tb <= '0';
        WAIT;
    END PROCESS;

    x_proc : PROCESS (clk_tb, rst_tb)
    BEGIN
        IF rst_tb = '1' THEN
            x <= (OTHERS => '0');
        ELSE
            IF rising_edge(clk_tb) THEN
                x <= x + 1;
            END IF;
        END IF;
    END PROCESS;

    x_comb <= x WHEN x < 10 ELSE
        (OTHERS => '-');

    y_proc : PROCESS (clk_tb, rst_tb)
    BEGIN
        IF rst_tb = '1' THEN
            y <= (OTHERS => '0');
        ELSE
            IF rising_edge(clk_tb) THEN
                IF x_comb < 9 THEN
                    y <= y + 1;
                ELSIF x_comb = 15 THEN
                    y <= (OTHERS => '0');
                ELSE
                    y <= (OTHERS => '-');
                END IF;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;