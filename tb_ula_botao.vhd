library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula_botao is
    port (
        clk       : in  std_logic;
        reset_btn : in  std_logic;
        a_btn     : in  std_logic;
        b_btn     : in  std_logic;
        ss_btn    : in  std_logic;

        s0_led    : out std_logic;
        s1_led    : out std_logic;
        over_led  : out std_logic;
        c_out_led : out std_logic;

        display   : out std_logic_vector(6 downto 0);
        an        : out std_logic_vector(5 downto 0)
    );
end ula_botao;

architecture Behavioral of ula_botao is

    -- Sinais
    signal a_reg, b_reg : signed(3 downto 0) := (others => '0');
    signal ss           : unsigned(1 downto 0) := (others => '0');
    signal f            : signed(3 downto 0);
    signal over, c_out  : std_logic;

    -- Botões anteriores (para detecção de borda)
    signal a_btn_last, b_btn_last, ss_btn_last, reset_btn_last : std_logic := '1';

    -- Multiplexador
    signal clk_div    : unsigned(15 downto 0) := (others => '0');
    signal mux_count  : unsigned(2 downto 0) := (others => '0');
    signal current_val : signed(3 downto 0);
    signal current_sign : std_logic;
    signal current_mag  : std_logic_vector(3 downto 0);

    -- Display
    signal digit : std_logic_vector(6 downto 0);

    -- Função para gerar magnitude e sinal
    function split_signed(x : signed(3 downto 0)) return std_logic_vector is
        variable mag : unsigned(3 downto 0);
    begin
        if x < 0 then
            mag := unsigned(-x);
        else
            mag := unsigned(x);
        end if;
        return std_logic_vector(mag);
    end function;

    -- Decodificador de 7 segmentos
    function seven_seg_decoder(bcd : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case bcd is
            when "0000" => seg := "1000000"; -- 0
            when "0001" => seg := "1111001"; -- 1
            when "0010" => seg := "0100100"; -- 2
            when "0011" => seg := "0110000"; -- 3
            when "0100" => seg := "0011001"; -- 4
            when "0101" => seg := "0010010"; -- 5
            when "0110" => seg := "0000010"; -- 6
            when "0111" => seg := "1111000"; -- 7
            when others => seg := "1111111"; -- off
        end case;
        return seg;
    end function;

begin

    -- Clock divisor
    process(clk)
    begin
        if rising_edge(clk) then
            clk_div <= clk_div + 1;
        end if;
    end process;

    -- Lógica dos botões
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_btn = '0' and reset_btn_last = '1' then
                a_reg <= (others => '0');
                b_reg <= (others => '0');
                ss    <= (others => '0');
            end if;

            if a_btn = '0' and a_btn_last = '1' then
                if a_reg < to_signed(7, 4) then
                    a_reg <= a_reg + 1;
                end if;
            end if;

            if b_btn = '0' and b_btn_last = '1' then
                if b_reg < to_signed(7, 4) then
                    b_reg <= b_reg + 1;
                end if;
            end if;

            if ss_btn = '0' and ss_btn_last = '1' then
                ss <= ss + 1;
            end if;

            a_btn_last     <= a_btn;
            b_btn_last     <= b_btn;
            ss_btn_last    <= ss_btn;
            reset_btn_last <= reset_btn;
        end if;
    end process;

    -- ULA
    process(a_reg, b_reg, ss)
        variable temp : signed(4 downto 0);
    begin
        over  <= '0';
        c_out <= '0';

        case ss is
            when "00" =>
                temp := resize(a_reg, 5) + resize(b_reg, 5);
                f    <= temp(3 downto 0);
                c_out <= temp(4);
                if (a_reg(3) = b_reg(3)) and (f(3) /= a_reg(3)) then
                    over <= '1';
                end if;

            when "01" =>
                temp := resize(a_reg, 5) - resize(b_reg, 5);
                f    <= temp(3 downto 0);
                c_out <= temp(4);
                if (a_reg(3) /= b_reg(3)) and (f(3) /= a_reg(3)) then
                    over <= '1';
                end if;

            when "10" =>
                f    <= a_reg and b_reg;
            when others =>
                f    <= a_reg or b_reg;
        end case;
    end process;

    -- Multiplexador
    process(clk)
    begin
        if rising_edge(clk) then
            mux_count <= mux_count + 1;
        end if;
    end process;

    process(mux_count, a_reg, b_reg, f)
    begin
        case mux_count is
            when "000" => -- Sinal de A
                current_sign <= a_reg(3);
                current_mag  <= split_signed(a_reg);
                an <= "111110"; -- ativar display 5 (mais significativo de A)
            when "001" => -- Valor de A
                current_sign <= '0';
                current_mag  <= split_signed(a_reg);
                an <= "111101"; -- display 4

            when "010" => -- Sinal de B
                current_sign <= b_reg(3);
                current_mag  <= split_signed(b_reg);
                an <= "111011"; -- display 3

            when "011" => -- Valor de B
                current_sign <= '0';
                current_mag  <= split_signed(b_reg);
                an <= "110111"; -- display 2

            when "100" => -- Sinal de F
                current_sign <= f(3);
                current_mag  <= split_signed(f);
                an <= "101111"; -- display 1

            when others => -- Valor de F
                current_sign <= '0';
                current_mag  <= split_signed(f);
                an <= "011111"; -- display 0
        end case;

        if current_sign = '1' then
            digit <= "0111111"; -- sinal de menos
        else
            digit <= seven_seg_decoder(current_mag);
        end if;
    end process;

    -- Saídas
    display    <= not digit;       -- lógica invertida
    s1_led     <= ss(1);
    s0_led     <= ss(0);
    over_led   <= over;
    c_out_led  <= c_out;

end Behavioral;
