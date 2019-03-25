library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library std;
use std.pkg_ram.all;;

PACKAGE pkg_bre IS

-- MAIN PARAMETERS
constant C_ENGINE_NCRITERIA         : integer := 9;
constant C_ENGINE_CRITERIUM_WIDTH   : integer := 16;

type query_in_array_type is array(C_ENGINE_NCRITERIA-1 downto 0) of std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);

-- CONTROL CODES
constant C_STRCT_SIMPLE     : integer := 0;
constant C_STRCT_PAIR       : integer := 1;

-- SIMPLE FUNCTORS
constant C_FNCTR_SIMP_DIE   : integer := 15; --
constant C_FNCTR_SIMP_DSE   : integer := 17; --
constant C_FNCTR_SIMP_MME   : integer := 99; -- [!] FAKE, CODE NOT KNOWN
constant C_FNCTR_SIMP_SEQ   : integer := 40; --

-- PAIR FUNCTORS
constant C_FNCTR_PAIR_PMA   : integer := 7;
constant C_FNCTR_PAIR_PAN   : integer := 8;
constant C_FNCTR_PAIR_PCA   : integer := 9;  -- [!] EQUALS TO 8 PAN CROSS

constant C_QUERY_RULE   : natural := 0;
constant C_QUERY_MRKTA  : natural := 1;
constant C_QUERY_MRKTB  : natural := 2;
constant C_QUERY_DATEA  : natural := 3;
constant C_QUERY_DATEB  : natural := 4;
constant C_QUERY_CABIN  : natural := 5;
constant C_QUERY_OPAIR  : natural := 6;
constant C_QUERY_FLGRP  : natural := 7;
constant C_QUERY_BKG    : natural := 8;
--
constant C_RULE_A       : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(1, C_ENGINE_CRITERIUM_WIDTH);
constant C_RULE_B       : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(2, C_ENGINE_CRITERIUM_WIDTH);
--
constant C_DT_04MAY2007 : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(0, C_ENGINE_CRITERIUM_WIDTH);
constant C_DT_15MAY2008 : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(1, C_ENGINE_CRITERIUM_WIDTH);
constant C_DT_07JUL2009 : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(2, C_ENGINE_CRITERIUM_WIDTH);
constant C_DT_08JUL2009 : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(3, C_ENGINE_CRITERIUM_WIDTH);
constant C_DT_18APR2015 : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(4, C_ENGINE_CRITERIUM_WIDTH);
constant C_DT_01JAN9999 : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := conv_std_logic_vector(5, C_ENGINE_CRITERIUM_WIDTH);
--
constant C_LBL_MKT_WORLD         : natural := 0;
constant C_LBL_MKT_OSL           : natural := 1;
constant C_LBL_MKT_EWR           : natural := 2;
constant C_LBL_MKT_CPH           : natural := 3;
constant C_LBL_MKT_OTHER         : natural := 4;
constant C_LBL_MKT_OFF           : natural := 5;
constant C_LBL_CAB_C             : natural := 0;
constant C_LBL_CAB_F             : natural := 1;
constant C_LBL_CAB_J             : natural := 2;
constant C_LBL_CAB_M             : natural := 3;
constant C_LBL_CAB_N             : natural := 4;
constant C_LBL_CAB_P             : natural := 5;
constant C_LBL_CAB_W             : natural := 6;
constant C_LBL_CAB_Y             : natural := 7;
constant C_LBL_CAB_OTHER         : natural := 8;
constant C_LBL_OPAIR_ALL         : natural := 0;
constant C_LBL_OPAIR_2X          : natural := 1;
constant C_LBL_OPAIR_8X          : natural := 2;
constant C_LBL_OPAIR_OTHER       : natural := 3;
constant C_LBL_OPAIR_OFF         : natural := 4;
constant C_LBL_FG_SBSFLIGHTS     : natural := 0;
constant C_LBL_FG_TRNPBCODE      : natural := 1;
constant C_LBL_FG_RMSOND         : natural := 2;
constant C_LBL_FG_SAFLIGHTS      : natural := 3;
constant C_LBL_FG_ALL2X          : natural := 4;
constant C_LBL_FG_101211093      : natural := 5;
constant C_LBL_FG_101211096      : natural := 6;
constant C_LBL_FG_101211097      : natural := 7;
constant C_LBL_FG_101211098      : natural := 8;
constant C_LBL_FG_101211099      : natural := 9;
constant C_LBL_FG_101211100      : natural := 10;
constant C_LBL_FG_105310439      : natural := 11;
constant C_LBL_FG_106769036      : natural := 12;
constant C_LBL_FG_PRODSLAALLFLTS : natural := 13;
constant C_LBL_BKG_A             : natural := 0;
constant C_LBL_BKG_B             : natural := 1;
constant C_LBL_BKG_C             : natural := 2;
constant C_LBL_BKG_D             : natural := 3;
constant C_LBL_BKG_E             : natural := 4;
constant C_LBL_BKG_F             : natural := 5;
constant C_LBL_BKG_G             : natural := 6;
constant C_LBL_BKG_H             : natural := 7;
constant C_LBL_BKG_I             : natural := 8;
constant C_LBL_BKG_J             : natural := 9;
constant C_LBL_BKG_K             : natural := 10;
constant C_LBL_BKG_L             : natural := 11;
constant C_LBL_BKG_M             : natural := 12;
constant C_LBL_BKG_N             : natural := 13;
constant C_LBL_BKG_O             : natural := 14;
constant C_LBL_BKG_P             : natural := 15;
constant C_LBL_BKG_Q             : natural := 16;
constant C_LBL_BKG_R             : natural := 17;
constant C_LBL_BKG_S             : natural := 18;
constant C_LBL_BKG_T             : natural := 19;
constant C_LBL_BKG_U             : natural := 20;
constant C_LBL_BKG_V             : natural := 21;
constant C_LBL_BKG_W             : natural := 22;
constant C_LBL_BKG_X             : natural := 23;
constant C_LBL_BKG_Y             : natural := 24;
constant C_LBL_BKG_Z             : natural := 25;
constant C_LBL_BKG_OFF           : natural := 26;
--
constant C_BRAM_MARKT_DEPTH      : natural := 6;
constant C_BRAM_MARKT_WIDTH      : natural := 4;
constant C_BRAM_CABIN_DEPTH      : natural := 9;
constant C_BRAM_CABIN_WIDTH      : natural := 8;
constant C_BRAM_OPAIR_DEPTH      : natural := 5;
constant C_BRAM_OPAIR_WIDTH      : natural := 3;
constant C_BRAM_FLGRP_DEPTH      : natural := 256;
constant C_BRAM_FLGRP_WIDTH      : natural := 14;
constant C_BRAM_BKG_DEPTH        : natural := 27;
constant C_BRAM_BKG_WIDTH        : natural := 26;
--





































--
constant C_MKT_WORLD                : std_logic_vector(7 downto 0) := "00000000";
constant C_MKT_OSL                  : std_logic_vector(7 downto 0) := "00000001";
constant C_MKT_EWR                  : std_logic_vector(7 downto 0) := "00000010";
constant C_MKT_CPH                  : std_logic_vector(7 downto 0) := "00000011";
constant C_MKT_UNDEFINED            : std_logic_vector(7 downto 0) := "00000111";
--
constant C_CABIN_C                  : std_logic_vector(7 downto 0) := "00000000";
constant C_CABIN_F                  : std_logic_vector(7 downto 0) := "00000001";
constant C_CABIN_J                  : std_logic_vector(7 downto 0) := "00000010";
constant C_CABIN_M                  : std_logic_vector(7 downto 0) := "00000011";
constant C_CABIN_P                  : std_logic_vector(7 downto 0) := "00000100";
constant C_CABIN_W                  : std_logic_vector(7 downto 0) := "00000101";
constant C_CABIN_Y                  : std_logic_vector(7 downto 0) := "00000110";
constant C_CABIN_ALL                : std_logic_vector(7 downto 0) := "00000111";
--
constant C_FLGHTGRP_101211100       : std_logic_vector(7 downto 0) := "00000000";
constant C_FLGHTGRP_101211093       : std_logic_vector(7 downto 0) := "00000001";
constant C_FLGHTGRP_101211096       : std_logic_vector(7 downto 0) := "00000010";
constant C_FLGHTGRP_101211097       : std_logic_vector(7 downto 0) := "00000011";
constant C_FLGHTGRP_101211098       : std_logic_vector(7 downto 0) := "00000100";
constant C_FLGHTGRP_101211099       : std_logic_vector(7 downto 0) := "00000101";
constant C_FLGHTGRP_106769036       : std_logic_vector(7 downto 0) := "00000110";
constant C_FLGHTGRP_ALL2X           : std_logic_vector(7 downto 0) := "00000111";
constant C_FLGHTGRP_PRODSLAALLFLTS  : std_logic_vector(7 downto 0) := "00001000";
constant C_FLGHTGRP_RMSOND          : std_logic_vector(7 downto 0) := "00001001";
constant C_FLGHTGRP_SAFLIGHTS       : std_logic_vector(7 downto 0) := "00001010";
constant C_FLGHTGRP_SBSFLIGHTS      : std_logic_vector(7 downto 0) := "00001011";
constant C_FLGHTGRP_TRNPBCODE       : std_logic_vector(7 downto 0) := "00001100";
constant C_FLGHTGRP_UNDEFINED       : std_logic_vector(7 downto 0) := "00001111";
--
constant C_BKG_A                    : std_logic_vector(7 downto 0) := "00000000";
constant C_BKG_B                    : std_logic_vector(7 downto 0) := "00000001";
constant C_BKG_C                    : std_logic_vector(7 downto 0) := "00000010";
constant C_BKG_D                    : std_logic_vector(7 downto 0) := "00000011";
constant C_BKG_E                    : std_logic_vector(7 downto 0) := "00000100";
constant C_BKG_F                    : std_logic_vector(7 downto 0) := "00000101";
constant C_BKG_G                    : std_logic_vector(7 downto 0) := "00000110";
constant C_BKG_H                    : std_logic_vector(7 downto 0) := "00000111";
constant C_BKG_I                    : std_logic_vector(7 downto 0) := "00001000";
constant C_BKG_J                    : std_logic_vector(7 downto 0) := "00001001";
constant C_BKG_K                    : std_logic_vector(7 downto 0) := "00001010";
constant C_BKG_L                    : std_logic_vector(7 downto 0) := "00001011";
constant C_BKG_M                    : std_logic_vector(7 downto 0) := "00001100";
constant C_BKG_N                    : std_logic_vector(7 downto 0) := "00001101";
constant C_BKG_O                    : std_logic_vector(7 downto 0) := "00001110";
constant C_BKG_P                    : std_logic_vector(7 downto 0) := "00001111";
constant C_BKG_Q                    : std_logic_vector(7 downto 0) := "00010000";
constant C_BKG_R                    : std_logic_vector(7 downto 0) := "00010001";
constant C_BKG_S                    : std_logic_vector(7 downto 0) := "00010010";
constant C_BKG_T                    : std_logic_vector(7 downto 0) := "00010011";
constant C_BKG_U                    : std_logic_vector(7 downto 0) := "00010100";
constant C_BKG_V                    : std_logic_vector(7 downto 0) := "00010101";
constant C_BKG_W                    : std_logic_vector(7 downto 0) := "00010110";
constant C_BKG_X                    : std_logic_vector(7 downto 0) := "00010111";
constant C_BKG_Y                    : std_logic_vector(7 downto 0) := "00011000";
constant C_BKG_Z                    : std_logic_vector(7 downto 0) := "00011001";
constant C_BKG_ALL                  : std_logic_vector(7 downto 0) := "00011111";
--
constant C_SOPAIR_2X                : std_logic_vector(7 downto 0) := "00000000";
constant C_SOPAIR_8X                : std_logic_vector(7 downto 0) := "00000001";
constant C_SOPAIR_ALL               : std_logic_vector(7 downto 0) := "00000011";

-----------------------------

component matcher
    generic (
        G_STRUCTURE         : integer;
        G_VALUE_A           : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        G_VALUE_B           : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := (others=>'0');
        G_FUNCTION_A        : integer;
        G_FUNCTION_B        : integer := 0;
        G_FUNCTION_PAIR     : integer := 0
    );    
    port (
        query_opA_i         :  in std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        query_opB_i         :  in std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0) := (others=>'0');
        match_result_o      : out std_logic
    );
end component;

component functor
    generic (
        G_VALUE         : std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        G_FUNCTION      : integer
    );    
    port (
        query_i         :  in std_logic_vector(C_ENGINE_CRITERIUM_WIDTH-1 downto 0);
        funct_o         : out std_logic
    );
end component;

component xilinx_single_port_ram_no_change is
    generic (
        RAM_WIDTH : integer;
        RAM_DEPTH : integer;
        RAM_PERFORMANCE : string;
        INIT_FILE : string
    );
    port (
        addra : in std_logic_vector(clogb2(RAM_DEPTH)-1 downto 0);
        dina  : in std_logic_vector(RAM_WIDTH-1 downto 0);
        clka  : in std_logic;
        wea   : in std_logic;
        ena   : in std_logic;
        rsta  : in std_logic;
        regcea: in std_logic;
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0)
    );
end component;

end pkg_bre;