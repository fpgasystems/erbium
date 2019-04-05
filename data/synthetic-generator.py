
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
	mandatory : bool
	functr    : Functor_Struct = Functor_Struct.NONE



C_ENGINE_CRITERIUM_WIDTH = 16
C_TOTAL_RULES = 100
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
			2800,
			True,
			Functor_Struct.SIMPLE
		),
		#VERSION
		Criteria(
			"VERS",
			Criteria_Struct.IDENTITY,
			5,
			True
		),
		#OWNER
		Criteria(
			"OWN",
			Criteria_Struct.FUNCTOR,
			1189,
			True,
			Functor_Struct.SIMPLE
		),
		#APPLICATION
		Criteria(
			"APP",
			Criteria_Struct.IDENTITY,
			45,
			True
		),
		#DATE
		Criteria(
			"DATE",
			Criteria_Struct.FUNCTOR,
			100,
			False,
			Functor_Struct.PAIR
		),
		#MARKET
		Criteria(
			"MKTA",
			Criteria_Struct.LUT,
			32,
			False
		),
		#MARKET
		Criteria(
			"MKTB",
			Criteria_Struct.LUT,
			32,
			False
		),
		#CABIN
		Criteria(
			"CABIN",
			Criteria_Struct.IDENTITY,
			8,
			False
		),
		#BKG
		Criteria(
			"BKG",
			Criteria_Struct.IDENTITY,
			26,
			False
		)
	]

	# libraries
	file.write(	"library ieee;\nuse ieee.std_logic_1164.all;\n"
			   	"\nlibrary std;\nuse std.pkg_ram.all;\n"
			   	"\nlibrary bre;\nuse bre.pkg_bre.all;\n\n")

	# entity
	file.write(	"entity top is\n"
				"\tPort (\n"
				"\t\tclk_i    :  in std_logic;\n"
				"\t\trst_i    :  in std_logic;\n"
				"\t\tquery_i  :  in query_in_array_type;\n"
				"\t\tresult_o : out std_logic_vector(157 downto 0);\n"
				"\t\tmem_i    :  in std_logic_vector(200 downto 0);\n"
				"\t\tmeme_i   :  in std_logic_vector(5 downto 0)\n"
				"\t);\n"
				"end top;\n\n")

	# architecture
	file.write("architecture behavioural of top is\n")
	aux = ""
	for iCriteria in full_criteria:
		if iCriteria.struct == Criteria_Struct.FUNCTOR:
			aux = "fnc"
		else:
			aux = "ram"
		file.write("\tsignal sig_"+aux+"_"+iCriteria.tag+"\t: std_logic_vector("+str(iCriteria.width-1)+" downto 0);\n")
	file.write("begin\n\n")

	# add constants
	# C_QUERY_"+iCriteria.tag+"
	# C_BRAM_"+iCriteria.tag+"_DEPTH
	# C_BRAM_"+iCriteria.tag+"_WIDTH
	# C_BRAM_"+iCriteria.tag+" : natural (order on mem_i_en)


	# for each criteria within the dataset
	for iCriteria in full_criteria:
		if iCriteria.struct == Criteria_Struct.FUNCTOR:

			# for each possible value within the criteria
			for iVal in range(iCriteria.width):
				file.write("fnc_"+iCriteria.tag+str(iVal)+" : matcher generic map (\n")

				if iCriteria.functr == Functor_Struct.SIMPLE:
					file.write("\tG_STRUCTURE         => C_STRCT_SIMPLE,\n")
					file.write("\tG_VALUE_A           => \""+dec2bin(iVal)+"\",\n")
					file.write("\tG_FUNCTION_A        => C_FNCTR_SIMP_SEQ\n")
					file.write(") port map (\n")
					file.write("\tquery_opA_i         => query_i(C_QUERY_"+iCriteria.tag+"),\n")
				elif iCriteria.functr == Functor_Struct.PAIR:
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
					file.write("\tquery_opA_i         => query_i(C_QUERY_"+iCriteria.tag+"A),\n")
					file.write("\tquery_opB_i         => query_i(C_QUERY_"+iCriteria.tag+"B),\n")
				file.write("\tmatch_result_o      => sig_fnc_"+iCriteria.tag+"("+str(iVal)+")\n);\n")

		else: #if iCriteria.struct == Criteria_Struct.IDENTITY:
			file.write("bram_"+iCriteria.tag+" : xilinx_single_port_ram_no_change generic map (\n")

			file.write("\tRAM_WIDTH => C_BRAM_"+iCriteria.tag+"_WIDTH,\n")
			file.write("\tRAM_DEPTH => C_BRAM_"+iCriteria.tag+"_DEPTH,\n")
			file.write("\tRAM_PERFORMANCE => \"LOW_LATENCY\", --\"HIGH_PERFORMANCE\",\n")
			file.write("\tINIT_FILE => \"bram_"+iCriteria.tag+".mem\"\n")
			file.write(") port map (\n")
			file.write("\tclka   => clk_i,\n")
			file.write("\taddra  => query_i(C_QUERY_"+iCriteria.tag+")((clogb2(C_BRAM_"+iCriteria.tag+"_DEPTH)-1) downto 0),\n")
			file.write("\tdina   => mem_i(C_BRAM_"+iCriteria.tag+"_WIDTH-1 downto 0),\n")
			file.write("\twea    => meme_i(C_BRAM_"+iCriteria.tag+"),\n")
			file.write("\tena    => '1',\n\trsta   => '0',\n\tregcea => '1',\n")
			file.write("\tdouta  => sig_"+aux+"_"+iCriteria.tag+"\n);\n")

			#		elif iCriteria.struct == Criteria_Struct.LUT:
			#			file.write("a lut here\n")
			#
			#		elif iCriteria.struct == Criteria_Struct.DDR:
			#			file.write("a ddr here\n")

	# aaaaaainnnnn: the ruuuuules
	for rule in range(C_TOTAL_RULES):
		file.write("sig_rule("+"{0:07d}".format(rule)+") <= ")

		for criteria in full_criteria:
			rnd = random.random();

			if criteria.mandatory or rdn > C_HAS_CRITERIA_THRESHOLD:
				
				rdn = random.randint(0,criteria.width-1);

				if criteria.struct == Criteria_Struct.FUNCTOR:
					aux = "fnc"
				else:
					aux = "ram"
				file.write("\n\t\tsig_"+aux+"_"+criteria.tag+"("+str(rdn)+")")
		file.write(";\n")
	file.close()

if __name__ == '__main__':
	main()