library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library bre;
use bre.engine_pkg.all;
use bre.core_pkg.all;

package cfg_criteria is

    -- CORE PARAMETERS ASC
    constant CORE_PARAM_0 : core_parameters_type := (
        G_RAM_DEPTH           => 4,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(8192, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_1 : core_parameters_type := (
        G_RAM_DEPTH           => 16,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(8, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_2 : core_parameters_type := (
        G_RAM_DEPTH           => 32,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(0, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '0'
    );
    constant CORE_PARAM_3 : core_parameters_type := (
        G_RAM_DEPTH           => 32,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(32768, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_4 : core_parameters_type := (
        G_RAM_DEPTH           => 64,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(32, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_5 : core_parameters_type := (
        G_RAM_DEPTH           => 128,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(2048, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_6 : core_parameters_type := (
        G_RAM_DEPTH           => 512,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(4096, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_7 : core_parameters_type := (
        G_RAM_DEPTH           => 2048,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(4, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_8 : core_parameters_type := (
        G_RAM_DEPTH           => 2048,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(2, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_9 : core_parameters_type := (
        G_RAM_DEPTH           => 2048,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(16384, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_10 : core_parameters_type := (
        G_RAM_DEPTH           => 4096,
        G_RAM_LATENCY         => 3,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(16, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_11 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_RAM_LATENCY         => 6,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(131072, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_12 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_RAM_LATENCY         => 10,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(128, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_13 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_RAM_LATENCY         => 10,
        G_MATCH_STRCT         => STRCT_PAIR,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_GEQ,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_LEQ,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_AND,
        G_MATCH_MODE          => MODE_FULL_ITERATION,
        G_WEIGHT              => std_logic_vector(to_unsigned(1, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_14 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_RAM_LATENCY         => 6,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(64, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_15 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_RAM_LATENCY         => 10,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(65536, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_16 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_RAM_LATENCY         => 10,
        G_MATCH_STRCT         => STRCT_PAIR,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_GEQ,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_LEQ,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_AND,
        G_MATCH_MODE          => MODE_FULL_ITERATION,
        G_WEIGHT              => std_logic_vector(to_unsigned(262144, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_17 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_RAM_LATENCY         => 10,
        G_MATCH_STRCT         => STRCT_PAIR,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_GEQ,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_LEQ,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_AND,
        G_MATCH_MODE          => MODE_FULL_ITERATION,
        G_WEIGHT              => std_logic_vector(to_unsigned(256, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_18 : core_parameters_type := (
        G_RAM_DEPTH           => 32768,
        G_RAM_LATENCY         => 10,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(524288, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_19 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_RAM_LATENCY         => 6,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(512, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '1'
    );
    constant CORE_PARAM_20 : core_parameters_type := (
        G_RAM_DEPTH           => 65536,
        G_RAM_LATENCY         => 18,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(0, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '0'
    );
    constant CORE_PARAM_21 : core_parameters_type := (
        G_RAM_DEPTH           => 16384,
        G_RAM_LATENCY         => 6,
        G_MATCH_STRCT         => STRCT_SIMPLE,
        G_MATCH_FUNCTION_A    => FNCTR_SIMP_EQU,
        G_MATCH_FUNCTION_B    => FNCTR_SIMP_NOP,
        G_MATCH_FUNCTION_PAIR => FNCTR_PAIR_NOP,
        G_MATCH_MODE          => MODE_STRICT_MATCH,
        G_WEIGHT              => std_logic_vector(to_unsigned(0, CFG_WEIGHT_WIDTH)),
        G_WILDCARD_ENABLED    => '0'
    );

    constant CFG_CORE_PARAM_ARRAY : CORE_PARAM_ARRAY := (
        CORE_PARAM_0,  CORE_PARAM_1,  CORE_PARAM_2,  CORE_PARAM_3,  CORE_PARAM_4,  CORE_PARAM_5, 
        CORE_PARAM_6,  CORE_PARAM_7,  CORE_PARAM_8,  CORE_PARAM_9,  CORE_PARAM_10, CORE_PARAM_11,
        CORE_PARAM_12, CORE_PARAM_13, CORE_PARAM_14, CORE_PARAM_15, CORE_PARAM_16, CORE_PARAM_17,
        CORE_PARAM_18, CORE_PARAM_19, CORE_PARAM_20, CORE_PARAM_21
    );

end cfg_criteria;

package body cfg_criteria is

end cfg_criteria;