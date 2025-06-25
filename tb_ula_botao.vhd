library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ula_botao is
end tb_ula_botao;

architecture sim of tb_ula_botao is

    signal clk        : std_logic := '0';
    signal reset_btn  : std_logic := '1';
    signal inc_a_btn  : std_logic := '1';
    signal inc_b_btn  : std_logic := '1';
    signal inc_ss_btn : std_logic := '1';

    signal f_display  : std_logic_vector(6 downto 0);
    signal f_bin_out  : std_logic_vector(3 downto 0);
    signal over_led   : std_logic;
    signal c_out_led  : std_logic;
    signal s1_led     : std_logic;
    signal s0_led     : std_logic;

    signal ss_val     : std_logic_vector(1 downto 0);
    signal a_val      : std_logic_vector(3 downto 0);
    signal b_val      : std_logic_vector(3 downto 0);

    constant clk_period : time := 10 ns;

    function to_bin_str(vec : std_logic_vector) return string is
        variable result : string(1 to vec'length);
    begin
        for i in vec'range loop
            result(i + 1 - vec'low) := character'value(std_ulogic'image(vec(i)));
        end loop;
        return result;
    end;

begin

    dut: entity work.ula_botao
        port map (
            clk         => clk,
            reset_btn   => reset_btn,
            a_btn       => inc_a_btn,
            b_btn       => inc_b_btn,
            ss_btn      => inc_ss_btn,
            f_display   => f_display,
            over_led    => over_led,
            c_out_led   => c_out_led,
            s1_led      => s1_led,
            s0_led      => s0_led,
            f_bin_out   => f_bin_out
        );

    ss_val <= s1_led & s0_led;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_btn = '0' then
                a_val <= (others => '0');
                b_val <= (others => '0');
            else
                if inc_a_btn = '0' then
                    a_val <= std_logic_vector(unsigned(a_val) + 1);
                end if;
                if inc_b_btn = '0' then
                    b_val <= std_logic_vector(unsigned(b_val) + 1);
                end if;
            end if;
        end if;
    end process;

    clk_process : process
    begin
        clk <= '0'; wait for clk_period / 2;
        clk <= '1'; wait for clk_period / 2;
    end process;

    stim_proc: process
        variable dec_val : integer;
    begin

        for a_int in 0 to 15 loop
            for b_int in 0 to 15 loop

                reset_btn <= '0'; wait for clk_period;
                reset_btn <= '1'; wait for clk_period;

                for i in 1 to a_int loop
                    inc_a_btn <= '0'; wait for clk_period; inc_a_btn <= '1'; wait for clk_period;
                end loop;

                for i in 1 to b_int loop
                    inc_b_btn <= '0'; wait for clk_period; inc_b_btn <= '1'; wait for clk_period;
                end loop;

                -- SOMA
                for i in 0 to 1 loop inc_ss_btn <= '1'; wait for clk_period; end loop;
                wait for clk_period;
                dec_val := to_integer(unsigned(f_bin_out));

                -- SUB
                inc_ss_btn <= '0'; wait for clk_period; inc_ss_btn <= '1'; wait for clk_period;
                wait for clk_period;
                dec_val := to_integer(unsigned(f_bin_out));

                -- AND
                inc_ss_btn <= '0'; wait for clk_period; inc_ss_btn <= '1'; wait for clk_period;
                wait for clk_period;

                -- OR
                inc_ss_btn <= '0'; wait for clk_period; inc_ss_btn <= '1'; wait for clk_period;
                wait for clk_period;
 
            end loop;
        end loop;

        wait;
    end process;

end sim;