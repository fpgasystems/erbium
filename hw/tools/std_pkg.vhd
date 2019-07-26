library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tools;

PACKAGE std_pkg IS

----------------------------------------------------------------------------------------------------
-- COMPONENTS IN std_pkg.vhd                                                                      --
----------------------------------------------------------------------------------------------------

    component uram_wrapper is
    generic (
        G_RAM_WIDTH : integer := 64;                   -- Specify RAM witdh (number of bits per row)
        G_RAM_DEPTH : integer := 1024                  -- Specify RAM depth (number of entries)
    );
    port (
        clk_i        :  in std_logic;
        rd_en_i      :  in std_logic;
        rd_addr_i    :  in std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        rd_data_o    : out std_logic_vector(G_RAM_WIDTH-1 downto 0);
        wr_en_i      :  in std_logic;
        wr_addr_i    :  in std_logic_vector(CFG_MEM_ADDR_WIDTH - 1 downto 0);
        wr_data_i    :  in std_logic_vector(G_RAM_WIDTH-1 downto 0)
    );
    end component;


    component simple_counter is
    generic (
        G_WIDTH   : integer := 8
    );
    port (
        clk_i     :  in std_logic;
        rst_i     :  in std_logic;
        enable_i  :  in std_logic;
        counter_o : out std_logic_vector(G_WIDTH - 1 downto 0)
    );
    end component;

----------------------------------------------------------------------------------------------------
-- FUNCTIONS IN std_pkg.vhd                                                                       --
----------------------------------------------------------------------------------------------------

    function v_or(d : std_logic_vector) return std_logic;
    function is_zero(d : std_logic_vector) return std_logic;
    function is_not_zero(d : std_logic_vector) return std_logic;
    function my_conv_integer(a: std_logic_vector) return integer;
    function notx(d : std_logic_vector) return boolean;
    function compare(a, b : std_logic_vector) return std_logic;
    function multiply(a, b : std_logic_vector) return std_logic_vector;
    function sign_extend(value: std_logic_vector; fill: std_logic; size: positive) return std_logic_vector;
    function add(a, b : std_logic_vector; ci: std_logic) return std_logic_vector;
    function increment(a : std_logic_vector) return std_logic_vector;
    function decrement(a : std_logic_vector) return std_logic_vector;
    function shift(value : std_logic_vector(31 downto 0); shamt: std_logic_vector(4 downto 0); s: std_logic; t: std_logic) return std_logic_vector;
    function shift_left(value : std_logic_vector(31 downto 0); shamt : std_logic_vector(4 downto 0)) return std_logic_vector;
    function shift_right(value : std_logic_vector(31 downto 0); shamt : std_logic_vector(4 downto 0); padding: std_logic) return std_logic_vector;
    function FLOOR (X : real ) return integer;
        -- returns largest integer value (as real) not greater than X

end std_pkg;

PACKAGE BODY std_pkg IS

-- Unary OR reduction
    function v_or(d : std_logic_vector) return std_logic is
        variable z : std_logic;
    begin
        z := '0';
        if notx (d) then
            for i in d'range loop
                z := z or d(i);
            end loop;
        end if;
        return z;
    end;

-- Check for ones in the vector
    function is_not_zero(d : std_logic_vector) return std_logic is
        variable z : std_logic_vector(d'range);
    begin
        z := (others => '0');
        if notx(d) then

            if d = z then
                return '0';
            else
                return '1';
            end if;

        else
            return '0';
        end if;
    end;

-- Check for ones in the vector
    function is_zero(d : std_logic_vector) return std_logic is
    begin
        return not is_not_zero(d);
    end;

    -- rewrite conv_integer to avoid modelsim warnings
    function my_conv_integer(a : std_logic_vector) return integer is
        variable res : integer range 0 to 2**a'length-1;
    begin
        res := 0;
        if (notx(a)) then
            res := to_integer(unsigned(a));
        end if;
        return res;
    end;

    function compare(a, b : std_logic_vector) return std_logic is
        variable z : std_logic;
    begin
        if notx(a & b) and a = b then
            return '1';
        else
            return '0';
        end if;
    end;

-- Unary NOT X test
    function notx(d : std_logic_vector) return boolean is
        variable res : boolean;
    begin
        res := true;
-- pragma translate_off
        res := not is_x(d);
-- pragma translate_on
        return (res);
    end;

-- -- 32 bit shifter
-- -- SYNOPSIS:
-- --    value: value to be shifted
-- --    shamt: shift amount
-- --    s 0 / 1: shift right / left
-- --    t 0 / 1: shift logical / arithmetic
-- -- PSEUDOCODE (from microblaze reference guide)
-- --     if S = 1 then
-- --          (rD) = (rA) << (rB)[27:31]
-- --     else
-- --      if T = 1 then
-- --         if ((rB)[27:31]) != 0 then
-- --              (rD)[0:(rB)[27:31]-1] = (rA)[0]
-- --              (rD)[(rB)[27:31]:31] = (rA) >> (rB)[27:31]
-- --         else
-- --              (rD) = (rA)
-- --      else
-- --         (rD) = (rA) >> (rB)[27:31]

    function shift(value: std_logic_vector(31 downto 0); shamt: std_logic_vector(4 downto 0); s: std_logic; t: std_logic) return std_logic_vector is
    begin
        if s = '1' then
            -- left arithmetic or logical shift
            return shift_left(value, shamt);
        else
            if t = '1' then
                -- right arithmetic shift
                return shift_right(value, shamt, value(31));
            else
                -- right logical shift
                return shift_right(value, shamt, '0');
            end if;
        end if;
    end;

    function shift_left(value: std_logic_vector(31 downto 0); shamt: std_logic_vector(4 downto 0)) return std_logic_vector is
        variable result: std_logic_vector(31 downto 0);
        variable paddings: std_logic_vector(15 downto 0);
    begin
        paddings := (others => '0');
        result := value;
        if (shamt(4) = '1') then result := result(15 downto 0) & paddings(15 downto 0); end if;
        if (shamt(3) = '1') then result := result(23 downto 0) & paddings( 7 downto 0); end if;
        if (shamt(2) = '1') then result := result(27 downto 0) & paddings( 3 downto 0); end if;
        if (shamt(1) = '1') then result := result(29 downto 0) & paddings( 1 downto 0); end if;
        if (shamt(0) = '1') then result := result(30 downto 0) & paddings( 0 );         end if;
        return result;
    end;

    function shift_right(value: std_logic_vector(31 downto 0); shamt: std_logic_vector(4 downto 0); padding: std_logic) return std_logic_vector is
        variable result: std_logic_vector(31 downto 0);
        variable paddings: std_logic_vector(15 downto 0);
    begin
        paddings := (others => padding);
        result := value;
        if (shamt(4) = '1') then result := paddings(15 downto 0) & result(31 downto 16); end if;
        if (shamt(3) = '1') then result := paddings( 7 downto 0) & result(31 downto  8); end if;
        if (shamt(2) = '1') then result := paddings( 3 downto 0) & result(31 downto  4); end if;
        if (shamt(1) = '1') then result := paddings( 1 downto 0) & result(31 downto  2); end if;
        if (shamt(0) = '1') then result := paddings( 0 )         & result(31 downto  1); end if;
        return result;
    end;

    function multiply(a, b: std_logic_vector) return std_logic_vector is
        variable x: std_logic_vector (a'length + b'length - 1 downto 0);
    begin
        x := std_logic_vector(signed(a) * signed(b));
        return x(31 downto 0);
    end;

    function sign_extend(value: std_logic_vector; fill: std_logic; size: positive) return std_logic_vector is
        variable a: std_logic_vector (size - 1 downto 0);
    begin
        a(size - 1 downto value'length) := (others => fill);
        a(value'length - 1 downto 0) := value;
        return a;
    end;

    function add(a, b : std_logic_vector; ci: std_logic) return std_logic_vector is
        variable x : std_logic_vector(a'length + 1 downto 0);
    begin
        x := (others => '0');
        if notx (a & b & ci) then
            x := std_logic_vector(signed('0' & a & '1') + signed('0' & b & ci));
        end if;
        return x(a'length + 1 downto 1);
    end;

    function increment(a : std_logic_vector) return std_logic_vector is
        variable x : std_logic_vector(a'length-1 downto 0);
    begin
        x := (others => '0');
        if notx (a) then
            x := std_logic_vector(signed(a) + 1);
        end if;
        return x;
    end;

    function decrement(a : std_logic_vector) return std_logic_vector is
        variable x : std_logic_vector(a'length-1 downto 0);
    begin
        x := (others => '0');
        if notx (a) then
            x := std_logic_vector(signed(a) - 1);
        end if;
        return x;
    end;

    function floor(X : real) return integer is
        -- returns largest integer value (as real) not greater than X
        -- No conversion to an integer type is expected, so truncate
        -- cannot overflow for large arguments.
        --
        variable large: real  := 1073741824.0;
        type long is range -1073741824 to 1073741824;
        -- 2**30 is longer than any single-precision mantissa
        variable rd: real;
    begin
        if abs( X ) >= large then
            return integer(X);
        else
            rd := real ( long( X));
            if X > 0.0 then
                if rd <= X then
                    return integer(rd);
                else
                    return integer(rd - 1.0);
                end if;
            elsif  X = 0.0  then
                return 0;
            else
                if rd >= X then
                    return integer(rd);
                else
                    return integer(rd + 1.0);
                end if;
            end if;
        end if;
  end floor;

end std_pkg;