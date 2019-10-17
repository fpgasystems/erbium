library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package engine_pkg is

    -- MAIN PARAMETERS
    constant CFG_ENGINE_DOPIO_CORES       : integer :=  1; -- Number of cores per engine (1 or 2)
    constant CFG_ENGINE_NCRITERIA         : integer := 22; -- Number of criteria
    constant CFG_CRITERION_VALUE_WIDTH    : integer := 13; -- Number of bits of each criterion value
    constant CFG_WEIGHT_WIDTH             : integer := 20; -- integer from 0 to 2^CFG_WEIGHT_WIDTH-1
    constant CFG_QUERY_ID_WIDTH           : integer :=  8; -- Used only internally
    constant CFG_FIRST_CRITERION_LOOKUP   : boolean := true; -- lookup table of first criterion
    --
    constant CFG_MEM_ADDR_WIDTH           : integer := 16;
    constant CFG_MEM_RD_LATENCY           : integer := 2;
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
    subtype RNG_BRAM_EDGE_STORE_WEIGHT    is natural range CFG_CRITERION_VALUE_WIDTH * 2 + CFG_MEM_ADDR_WIDTH + CFG_WEIGHT_WIDTH - 1 downto CFG_CRITERION_VALUE_WIDTH * 2 + CFG_MEM_ADDR_WIDTH;
    subtype RNG_BRAM_EDGE_STORE_LAST      is natural range CFG_CRITERION_VALUE_WIDTH * 2 + CFG_MEM_ADDR_WIDTH + CFG_WEIGHT_WIDTH downto CFG_CRITERION_VALUE_WIDTH * 2 + CFG_MEM_ADDR_WIDTH + CFG_WEIGHT_WIDTH;

end engine_pkg;

package body engine_pkg is

end engine_pkg;