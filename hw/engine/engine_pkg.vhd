----------------------------------------------------------------------------------------------------
--  ERBium - Business Rule Engine Hardware Accelerator
--  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

--  This program is free software: you can redistribute it and/or modify it under the terms of the
--  GNU Affero General Public License as published by the Free Software Foundation, either version 3
--  of the License, or (at your option) any later version.

--  This software is provided by the copyright holders and contributors "AS IS" and any express or
--  implied warranties, including, but not limited to, the implied warranties of merchantability and
--  fitness for a particular purpose are disclaimed. In no event shall the copyright holder or
--  contributors be liable for any direct, indirect, incidental, special, exemplary, or
--  consequential damages (including, but not limited to, procurement of substitute goods or
--  services; loss of use, data, or profits; or business interruption) however caused and on any
--  theory of liability, whether in contract, strict liability, or tort (including negligence or
--  otherwise) arising in any way out of the use of this software, even if advised of the 
--  possibility of such damage. See the GNU Affero General Public License for more details.

--  You should have received a copy of the GNU Affero General Public License along with this
--  program. If not, see <http://www.gnu.org/licenses/agpl-3.0.en.html>.
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library erbium;
use erbium.cfg_engines.all;

package engine_pkg is

    -- MAIN PARAMETERS
    constant CFG_ENGINE_DOPIO_CORES       : integer :=  2; -- Number of cores per engine (1 or 2)
    constant CFG_ENGINES_NUMBER           : integer := THE_CFG_ENGINES_NUMBER; -- Number of engines per bitstrea
    constant CFG_ENGINE_NCRITERIA         : integer := 22; -- Number of criteria
    constant CFG_CRITERION_VALUE_WIDTH    : integer := 13; -- Number of bits of each criterion value
    constant CFG_WEIGHT_WIDTH             : integer := 31; -- integer from 0 to 2^CFG_WEIGHT_WIDTH-1
    constant CFG_QUERY_ID_WIDTH           : integer :=  8; -- Used only internally
    constant CFG_FIRST_CRITERION_LOOKUP   : boolean := true; -- lookup table of first criterion
    --
    constant CFG_MEM_ADDR_WIDTH           : integer := 16;
    --
    constant CFG_QUERY_BUFFER_DEPTH       : integer := CFG_ENGINE_NCRITERIA;
    --
    constant CFG_EDGE_BUFFERS_DEPTH       : integer := CFG_ENGINE_NCRITERIA+2;
    constant CFG_EDGE_BRAM_WIDTH          : integer := 64; -- bits
    --
    constant CFG_DBG_N_OF_CLK_CYCS_WIDTH  : integer := 16;
    constant CFG_DBG_COUNTERS_WIDTH       : integer := 16;

    --
    -- Number of bits for each criterion value coming from memory (top level)
    constant CFG_RAW_QUERY_WIDTH          : integer := 16; -- bits

    -- Number of bits for each result value going back to the memory (wrapper level)
    constant CFG_RAW_RESULTS_WIDTH        : integer := 16; -- bits
    constant CFG_RAW_RESULT_STATS_WIDTH   : integer := 64; -- bits (result value comprised)

    -- MEMORY DATA SLICE RANGES
    subtype RNG_BRAM_EDGE_STORE_OPERAND_A is natural range CFG_CRITERION_VALUE_WIDTH - 1 downto 0;
    subtype RNG_BRAM_EDGE_STORE_OPERAND_B is natural range CFG_CRITERION_VALUE_WIDTH * 2 - 1 downto CFG_CRITERION_VALUE_WIDTH;
    subtype RNG_BRAM_EDGE_STORE_POINTER   is natural range CFG_CRITERION_VALUE_WIDTH * 2 + CFG_MEM_ADDR_WIDTH - 1 downto CFG_CRITERION_VALUE_WIDTH * 2;
    subtype RNG_BRAM_EDGE_STORE_LAST      is natural range CFG_CRITERION_VALUE_WIDTH * 2 + CFG_MEM_ADDR_WIDTH downto CFG_CRITERION_VALUE_WIDTH * 2 + CFG_MEM_ADDR_WIDTH;

end engine_pkg;

package body engine_pkg is

end engine_pkg;