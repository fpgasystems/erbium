library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package engine_pkg is

    -- MAIN PARAMETERS
    constant CFG_ENGINE_NCRITERIA         : integer := 22; -- Number of criteria
    constant CFG_CRITERION_VALUE_WIDTH    : integer := 14; -- Number of bits of each criterion value
    constant CFG_WEIGHT_WIDTH             : integer := 19; -- integer from 0 to 2^CFG_WEIGHT_WIDTH-1
    constant CFG_QUERY_ID_WIDTH           : integer :=  8; -- Used only internally
    --
    constant CFG_MEM_ADDR_WIDTH           : integer := 15;
    --
    constant CFG_QUERY_BUFFER_DEPTH       : integer := CFG_ENGINE_NCRITERIA;
    --
    constant CFG_EDGE_BUFFERS_DEPTH       : integer := CFG_ENGINE_NCRITERIA;
    constant CFG_EDGE_BRAM_DEPTH          : integer := 32768;--30690;
    constant CFG_EDGE_BRAM_WIDTH          : integer := 64;
    --
    -- Number of bits for each criterion (hence, for two values) coming from memory (top level)
    constant CFG_RAW_QUERY_WIDTH          : integer := 32;

    -- MEMORY DATA SLICE RANGES
    subtype RNG_BRAM_EDGE_STORE_OPERAND_A is natural range CFG_CRITERION_VALUE_WIDTH - 1 downto 0;
    subtype RNG_BRAM_EDGE_STORE_OPERAND_B is natural range CFG_CRITERION_VALUE_WIDTH*2 - 1 downto CFG_CRITERION_VALUE_WIDTH;
    subtype RNG_BRAM_EDGE_STORE_POINTER   is natural range CFG_CRITERION_VALUE_WIDTH*2 + CFG_MEM_ADDR_WIDTH - 1 downto CFG_CRITERION_VALUE_WIDTH*2;
    subtype RNG_BRAM_EDGE_STORE_WEIGHT    is natural range CFG_CRITERION_VALUE_WIDTH*2 + CFG_MEM_ADDR_WIDTH + CFG_WEIGHT_WIDTH - 1 downto CFG_CRITERION_VALUE_WIDTH*2 + CFG_MEM_ADDR_WIDTH;
    subtype RNG_BRAM_EDGE_STORE_LAST      is natural range CFG_CRITERION_VALUE_WIDTH*2 + CFG_MEM_ADDR_WIDTH + CFG_WEIGHT_WIDTH downto CFG_CRITERION_VALUE_WIDTH*2 + CFG_MEM_ADDR_WIDTH + CFG_WEIGHT_WIDTH;

end engine_pkg;

package body engine_pkg is

end engine_pkg;