library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula_botao is
    port (
        clk       : in std_logic;  -- clock pra fazer o botao funfar
        reset_btn : in std_logic;  -- reset
        a_btn     : in std_logic;  -- botão A 
        b_btn     : in std_logic;  -- botão B 
        ss_btn    : in std_logic;  -- botão SS 

        f_display : out std_logic_vector(6 downto 0); -- display 
        over_led  : out std_logic;
        c_out_led : out std_logic;
        s1_led    : out std_logic;
        s0_led    : out std_logic;
        f_bin_out : out std_logic_vector(3 downto 0)  -- saída binaria

    );
end ula_botao;

architecture behavior of ula_botao is


    signal a_reg, b_reg : unsigned(3 downto 0) := (others => '0');
    signal ss           : unsigned(1 downto 0) := (others => '0');
    signal f            : unsigned(3 downto 0);
    signal over, c_out  : std_logic;

    -- debounce e detecção de borda pro botao
    signal a_btn_last, b_btn_last, ss_btn_last, reset_btn_last : std_logic := '1';

begin

    process(clk)
    begin
        if rising_edge(clk) then

            -- reset 
            if reset_btn = '0' and reset_btn_last = '1' then
                a_reg <= (others => '0');
                b_reg <= (others => '0');
                ss    <= (others => '0');
            end if;

            -- +A
            if a_btn = '0' and a_btn_last = '1' then
                if a_reg < 15 then
                    a_reg <= a_reg + 1;
                end if;
            end if;

            -- +B
            if b_btn = '0' and b_btn_last = '1' then
                if b_reg < 15 then
                    b_reg <= b_reg + 1;
                end if;
            end if;

            -- +SS
            if ss_btn = '0' and ss_btn_last = '1' then
                ss <= ss + 1;
            end if;

            -- atualiza botões
            a_btn_last     <= a_btn;
            b_btn_last     <= b_btn;
            ss_btn_last    <= ss_btn;
            reset_btn_last <= reset_btn;

        end if;
    end process;

    process(a_reg, b_reg, ss)
        variable temp : unsigned(4 downto 0);
    begin
        over   <= '0';
        c_out  <= '0';

        case ss is
            when "00" => -- soma
                temp := ('0' & a_reg) + ('0' & b_reg);
                f     <= temp(3 downto 0);
                c_out <= temp(4);
                -- overflow 
                if (a_reg(3) = b_reg(3)) and (f(3) /= a_reg(3)) then
                    over <= '1';
                end if;

            when "01" => -- subtração 
                temp := ('0' & a_reg) - ('0' & b_reg);
                f     <= temp(3 downto 0);
                c_out <= temp(4);
                -- overflow para subtração com sinal
                if (a_reg(3) /= b_reg(3)) and (f(3) /= a_reg(3)) then
                    over <= '1';
                end if;

            when "10" => -- and
                f     <= a_reg and b_reg;
                over  <= '0';
                c_out <= '0';

            when others => -- or
                f     <= a_reg or b_reg;
                over  <= '0';
                c_out <= '0';
        end case;
    end process;

    over_led  <= over;
    c_out_led <= c_out;
    s1_led    <= ss(1);
    s0_led    <= ss(0);
    f_bin_out <= std_logic_vector(f);


    -- (vai de 0 a 15)
    with f select
        f_display <= "1000000" when "0000", -- 0
                      "1111001" when "0001", -- 1
                      "0100100" when "0010", -- 2
                      "0110000" when "0011", -- 3
                      "0011001" when "0100", -- 4
                      "0010010" when "0101", -- 5
                      "0000010" when "0110", -- 6
                      "1111000" when "0111", -- 7
                      "0000000" when "1000", -- 8
                      "0010000" when "1001", -- 9
                      "0001000" when "1010", -- A
                      "0000011" when "1011", -- b
                      "1000110" when "1100", -- C
                      "0100001" when "1101", -- d
                      "0000110" when "1110", -- E
                      "0001110" when others;  -- F

end behavior;
