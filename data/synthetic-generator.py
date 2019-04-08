
from dataclasses import dataclass
from enum import Enum
import random

class Criteria_Struct(Enum):
	FUNCTOR  = 0
	IDENTITY = 1
	LUT      = 2
	DDR      = 3

class Functor_Struct(Enum):
	NONE   = 0
	SIMPLE = 1
	PAIR   = 2

@dataclass
class Criteria:
	tag       : str
	struct    : Criteria_Struct
	width     : int 				# number of different matching values
	depth     : int                 # number of different input values
	mandatory : bool
	functr    : Functor_Struct = Functor_Struct.NONE



C_ENGINE_CRITERIUM_WIDTH = 16
C_TOTAL_RULES = 1024
C_HAS_CRITERIA_THRESHOLD = 0.7

def dec2bin(decimal, width = C_ENGINE_CRITERIUM_WIDTH):
	if width == C_ENGINE_CRITERIUM_WIDTH:
		return "{0:016b}".format(decimal)
	else:
		return ("{0:0"+str(width)+"b}").format(decimal)

def main():
	file = open("top_synthetic.vhd","w")

	full_criteria = [
		#RT_ID
		Criteria(
			"RTD",
			Criteria_Struct.FUNCTOR,
			width=2800,
			depth=2800,#not used
			mandatory=True,
			functr=Functor_Struct.SIMPLE
		),
		#VERSION
		Criteria(
			"VERS",
			Criteria_Struct.IDENTITY,
			width=5,
			depth=8,
			mandatory=True
		),
		#OWNER
		Criteria(
			"OWN",
			Criteria_Struct.FUNCTOR,
			width=1189,
			depth=1189,#not used
			mandatory=True,
			functr=Functor_Struct.SIMPLE
		),
		#APPLICATION
		Criteria(
			"APP",
			Criteria_Struct.IDENTITY,
			width=45,
			depth=46,
			mandatory=True
		),
		#DATE
		Criteria(
			"DATE",
			Criteria_Struct.FUNCTOR,
			width=100,
			depth=100,#not used
			mandatory=False,
			functr=Functor_Struct.PAIR
		),
		#MARKET
		Criteria(
			"MKTA",
			Criteria_Struct.LUT,
			width=32,
			depth=128,
			mandatory=False
		),
		#MARKET
		Criteria(
			"MKTB",
			Criteria_Struct.LUT,
			width=32,
			depth=128,
			mandatory=False
		),
		#CABIN
		Criteria(
			"CABIN",
			Criteria_Struct.IDENTITY,
			width=8,
			depth=9,
			mandatory=False
		),
		#BKG
		Criteria(
			"BKG",
			Criteria_Struct.IDENTITY,
			width=26,
			depth=27,
			mandatory=False
		)
	]

	# libraries
	file.write(	"library ieee;\nuse ieee.std_logic_1164.all;\n"
			   	"\nlibrary std;\nuse std.pkg_ram.all;\n"
			   	"\nlibrary bre;\nuse bre.pkg_bre.all;\n\n")

	# entity
	file.write(	"entity top_synt is\n"
				"\tPort (\n"
				"\t\tclk_i    :  in std_logic;\n"
				"\t\trst_i    :  in std_logic;\n"
				"\t\tquery_i  :  in query_in_array_type;\n"
				"\t\tresult_o : out std_logic_vector("+str(C_TOTAL_RULES-1)+" downto 0);\n"
				"\t\tmem_i    :  in std_logic_vector(200 downto 0);\n"
				"\t\tmeme_i   :  in std_logic_vector(5 downto 0)\n"
				"\t);\n"
				"end top_synt;\n\n")

	# architecture
	file.write("architecture behavioural of top_synt is\n")

	# OK C_QUERY_"+criteria.tag+"
	aux = 0
	for criteria in full_criteria:
		file.write("\tconstant C_BRAM_"+criteria.tag+"_DEPTH\t: natural := "+str(criteria.depth)+";\n")
		file.write("\tconstant C_BRAM_"+criteria.tag+"_WIDTH\t: natural := "+str(criteria.width)+";\n")
		if criteria.struct != Criteria_Struct.FUNCTOR:
			file.write("\tconstant C_BRAM_"+criteria.tag+"\t\t: natural := "+str(aux)+";\n")
			aux += 1

	# C_BRAM_"+criteria.tag+"_DEPTH
	# C_BRAM_"+criteria.tag+"_WIDTH
	# C_BRAM_"+criteria.tag+" : natural (order on mem_i_en)

	aux = ""
	for criteria in full_criteria:
		if criteria.struct == Criteria_Struct.FUNCTOR:
			aux = "fnc"
			file.write("\tsignal sig_"+aux+"_"+criteria.tag+"_r\t: std_logic_vector("+str(criteria.width-1)+" downto 0);\n")
		else:
			aux = "ram"
		file.write("\tsignal sig_"+aux+"_"+criteria.tag+"\t\t: std_logic_vector("+str(criteria.width-1)+" downto 0);\n")
	file.write("\tsignal sig_rule\t\t\t: std_logic_vector("+str(C_TOTAL_RULES-1)+" downto 0);\n")
	file.write("begin\n\n")



	# for each criteria within the dataset
	for criteria in full_criteria:
		if criteria.struct == Criteria_Struct.FUNCTOR:

			# for each possible value within the criteria
			for iVal in range(criteria.width):
				file.write("fnc_"+criteria.tag+str(iVal)+" : matcher generic map (\n")

				if criteria.functr == Functor_Struct.SIMPLE:
					file.write("\tG_STRUCTURE         => C_STRCT_SIMPLE,\n")
					file.write("\tG_VALUE_A           => \""+dec2bin(iVal)+"\",\n")
					file.write("\tG_FUNCTION_A        => C_FNCTR_SIMP_SEQ\n")
					file.write(") port map (\n")
					file.write("\tquery_opA_i         => query_i(C_QUERY_"+criteria.tag+"),\n")
				elif criteria.functr == Functor_Struct.PAIR:
					# two random values between 0 and 2^16, such as A < B
					aux_a = int(random.random()*(2**16)-1)
					aux_b = int(random.random()*(2**16)-1)
					file.write("\tG_STRUCTURE         => C_STRCT_PAIR,\n")
					file.write("\tG_VALUE_A           => \""+dec2bin(min(aux_a,aux_b))+"\",\n")
					file.write("\tG_VALUE_B           => \""+dec2bin(max(aux_a,aux_b))+"\",\n")
					file.write("\tG_FUNCTION_A        => C_FNCTR_SIMP_DSE,\n")
					file.write("\tG_FUNCTION_B        => C_FNCTR_SIMP_DIE,\n")
					file.write("\tG_FUNCTION_PAIR     => C_FNCTR_PAIR_PCA\n")
					file.write(") port map (\n")
					file.write("\tquery_opA_i         => query_i(C_QUERY_"+criteria.tag+"A),\n")
					file.write("\tquery_opB_i         => query_i(C_QUERY_"+criteria.tag+"B),\n")
				file.write("\tmatch_result_o      => sig_fnc_"+criteria.tag+"("+str(iVal)+")\n);\n")

		else: #if criteria.struct == Criteria_Struct.IDENTITY:
			file.write("bram_"+criteria.tag+" : xilinx_single_port_ram_no_change generic map (\n")

			file.write("\tRAM_WIDTH => C_BRAM_"+criteria.tag+"_WIDTH,\n")
			file.write("\tRAM_DEPTH => C_BRAM_"+criteria.tag+"_DEPTH,\n")
			file.write("\tRAM_PERFORMANCE => \"LOW_LATENCY\", --\"HIGH_PERFORMANCE\",\n")
			file.write("\tINIT_FILE => \"bram_"+criteria.tag+".mem\"\n")
			file.write(") port map (\n")
			file.write("\tclka   => clk_i,\n")
			file.write("\taddra  => query_i(C_QUERY_"+criteria.tag+")((clogb2(C_BRAM_"+criteria.tag+"_DEPTH)-1) downto 0),\n")
			file.write("\tdina   => mem_i(C_BRAM_"+criteria.tag+"_WIDTH-1 downto 0),\n")
			file.write("\twea    => meme_i(C_BRAM_"+criteria.tag+"),\n")
			file.write("\tena    => '1',\n\trsta   => '0',\n\tregcea => '1',\n")
			file.write("\tdouta  => sig_"+aux+"_"+criteria.tag+"\n);\n")

			#		elif criteria.struct == Criteria_Struct.LUT:
			#			file.write("a lut here\n")
			#
			#		elif criteria.struct == Criteria_Struct.DDR:
			#			file.write("a ddr here\n")

	# aaaaaainnnnn: the ruuuuules
	for rule in range(C_TOTAL_RULES):
		file.write("sig_rule("+"{0:07d}".format(rule)+") <= ")

		aux = False;
		for criteria in full_criteria:
			rnd = random.random();

			if criteria.mandatory or rdn > C_HAS_CRITERIA_THRESHOLD:
				
				if(aux):
					file.write("\n\t\t\t\t and ")
				aux = True

				rdn = random.randint(0,criteria.width-1);

				if criteria.struct == Criteria_Struct.FUNCTOR:
					file.write("sig_fnc_"+criteria.tag+"_r("+str(rdn)+")")
				else:
					file.write("sig_ram_"+criteria.tag+"("+str(rdn)+")")
		file.write(";\n")

	#process
	file.write("\nprocess(clk_i, rst_i)\nbegin\n\tif rst_i = '1' then\n")
	file.write("\t\tresult_o <= (others => '0');\n")
	for criteria in full_criteria:
		if criteria.struct == Criteria_Struct.FUNCTOR:
			file.write("\t\tsig_fnc_"+criteria.tag+"_r <= (others => '0');\n")
	file.write("\telsif rising_edge(clk_i) then\n")
	for criteria in full_criteria:
		if criteria.struct == Criteria_Struct.FUNCTOR:
			file.write("\t\tsig_fnc_"+criteria.tag+"_r <= sig_fnc_"+criteria.tag+";\n")
	file.write("\t\tresult_o <= sig_rule;\n")
	file.write("\tend if;\nend process;\n")

	#end architecture
	file.write("\nend architecture behavioural;")

	file.close()

if __name__ == '__main__':
	main()