library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tools;

package ram_pkg is
    function clogb2 (depth: in natural) return integer;
end ram_pkg;

package body ram_pkg is

function clogb2( depth : natural) return integer is
variable temp    : integer := depth;
variable ret_val : integer := 0;
begin
    while temp > 1 loop
        ret_val := ret_val + 1;
        temp    := temp / 2;
    end loop;

    if (depth mod 2) = 1 then
        ret_val := ret_val + 1;
    end if;

    return ret_val;
end function;

end package body ram_pkg;