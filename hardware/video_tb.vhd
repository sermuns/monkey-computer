LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.stop;

ENTITY video_tb IS
END ENTITY;

ARCHITECTURE testbench OF video_tb IS
    -- Constants
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals
    SIGNAL clk_tb : STD_LOGIC := '0';
    SIGNAL rst_tb : STD_LOGIC := '1';

    SIGNAL clock_count_tb : NATURAL := 0;
    CONSTANT MAX_CLK_COUNT : NATURAL := 2e6;
    -- CONSTANT MAX_CLK_COUNT : NATURAL := 60;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    UUT : ENTITY work.vga_motor
        PORT MAP(
            clk => clk_tb,
            rst => rst_tb,
            vmem_address_out => OPEN,
            vmem_data => (OTHERS => '0'),
            vga_hsync => OPEN,
            vga_vsync => OPEN,
            vga_red => OPEN,
            vga_green => OPEN,
            vga_blue => OPEN
        );

    -- Clock process
    clk_process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        clk_tb <= NOT clk_tb;

        IF now > CLK_PERIOD * MAX_CLK_COUNT THEN
            REPORT "Simulation has continued for longer than MAX_CLK_COUNT, stopping";
            STOP;
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
        rst_tb <= '1';
        WAIT FOR CLK_PERIOD * 1.25;
        rst_tb <= '0';

        WAIT;

    END PROCESS;

END ARCHITECTURE;