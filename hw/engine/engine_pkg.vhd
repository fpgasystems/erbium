----------------------------------------------------------------------------------------------
--
--      Input file         : engine_pkg.vhd
--      Design name        : engine_pkg
--      Author             : Tamar Kranenburg
--      Company            : Delft University of Technology
--                         : Faculty EEMCS, Department ME&CE
--                         : Systems and Circuits group
--
--      Description        : Package with components and type definitions for the interface
--                           of the components
--
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package engine_pkg is

    -- MAIN PARAMETERS
    constant CFG_ENGINE_NCRITERIA         : integer := 22; -- Number of criteria
    constant CFG_ENGINE_CRITERIUM_WIDTH   : integer := 12; -- Number of bits of each criterium value
    constant CFG_WEIGHT_WIDTH             : integer := 19; -- integer from 0 to 2^CFG_WEIGHT_WIDTH-1
    --
    constant CFG_MEM_ADDR_WIDTH           : integer := 3;
    --
    constant CFG_EDGE_BUFFERS_DEPTH       : integer := 5;
    constant CFG_EDGE_BRAM_DEPTH          : integer := 8;

end engine_pkg;

package body engine_pkg is

end engine_pkg;