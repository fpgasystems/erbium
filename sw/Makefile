####################################################################################################
##  ERBium - Business Rule Engine Hardware Accelerator
##  Copyright (C) 2020 Fabio Maschi - Systems Group, ETH Zurich

##  This program is free software: you can redistribute it and/or modify it under the terms of the
##  GNU Affero General Public License as published by the Free Software Foundation, either version 3
##  of the License, or (at your option) any later version.

##  This software is provided by the copyright holders and contributors "AS IS" and any express or
##  implied warranties, including, but not limited to, the implied warranties of merchantability and
##  fitness for a particular purpose are disclaimed. In no event shall the copyright holder or
##  contributors be liable for any direct, indirect, incidental, special, exemplary, or
##  consequential damages (including, but not limited to, procurement of substitute goods or
##  services; loss of use, data, or profits; or business interruption) however caused and on any
##  theory of liability, whether in contract, strict liability, or tort (including negligence or
##  otherwise) arising in any way out of the use of this software, even if advised of the 
##  possibility of such damage. See the GNU Affero General Public License for more details.

##  You should have received a copy of the GNU Affero General Public License along with this
##  program. If not, see <http://www.gnu.org/licenses/agpl-3.0.en.html>.
####################################################################################################
# from https://gist.github.com/maxtruxa/4b3929e118914ccef057f8a05c614b0f

# output binary
BIN := erbium

# source files
SRCS := $(shell find . -name "*.cc")
SRCS := $(patsubst ./%, %, $(SRCS))

# intermediate directory for generated object files
OBJDIR := .o
# intermediate directory for generated dependency files
DEPDIR := .d

# object files, auto generated from source files
OBJS := $(patsubst %,$(OBJDIR)/%.o,$(basename $(SRCS)))
# dependency files, auto generated from source files
DEPS := $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS)))

# compilers (at least gcc and clang) don't create the subdirectories automatically
$(shell mkdir -p $(dir $(OBJS)) >/dev/null)
$(shell mkdir -p $(dir $(DEPS)) >/dev/null)

# C compiler
CC := gcc
# C++ compiler
CXX := gcc
# linker
LD := g++
# tar
TAR := tar

# C++ flags
CXXFLAGS := -O3
# C/C++ flags
CPPFLAGS := -g -Wall -pedantic -fopenmp -O3
# linker flags
LDFLAGS := -fopenmp
# flags required for dependency generation; passed to compilers
DEPFLAGS = -MT $@ -MD -MP -MF $(DEPDIR)/$*.Td

# compile C++ source files
COMPILE.cc = $(CXX) $(DEPFLAGS) $(CXXFLAGS) $(CPPFLAGS) -c -o $@
# link object files to binary
LINK.o = $(LD) $(LDFLAGS) $(LDLIBS) -o $@
# precompile step
PRECOMPILE =
# postcompile step
POSTCOMPILE = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d

.PHONY: all clean cleanall help
all: $(BIN)

.PHONY: demo
demo: all
	mkdir -p build-demo01
	mkdir -p build-demo02
	./$(BIN) -d build-demo01 -r ../data/demo_01.csv -s 0 -t ../data/demo_ruletype.xml
	./$(BIN) -d build-demo02 -r ../data/demo_02.csv -s 0 -t ../data/demo_ruletype.xml

.PHONY: sample
sample: all
	mkdir -p build-$(AIRPORT)
	./$(BIN) -d build-$(AIRPORT) -r ../data/mct_rules-$(AIRPORT).csv -s 4 >> build-$(AIRPORT)/log.txt

.PHONY: benchmarks
benchmarks: all
	mkdir -p build-mct_h1Asc
	mkdir -p build-mct_h1Des
	mkdir -p build-mct_hRand
	mkdir -p build-mct_h2Asc
	mkdir -p build-mct_h2Des
	mkdir -p build-zrh_h2Des
	./$(BIN) -d build-mct_h1Asc -r ../data/mct_rules.csv -s 1 >> build-mct_h1Asc/log.txt
	./$(BIN) -d build-mct_h1Des -r ../data/mct_rules.csv -s 2 >> build-mct_h1Des/log.txt
	./$(BIN) -d build-mct_hRand -r ../data/mct_rules.csv -s 0 >> build-mct_hRand/log.txt
	./$(BIN) -d build-mct_h2Asc -r ../data/mct_rules.csv -s 3 >> build-mct_h2Asc/log.txt
	./$(BIN) -d build-mct_h2Des -r ../data/mct_rules.csv -s 4 >> build-mct_h2Des/log.txt
	./$(BIN) -d build-zrh_h2Des -r ../data/mct_rules-zrh.csv -s 4 >> build-zrh_h2Des/log.txt

clean:
	$(RM) -r $(OBJDIR) $(DEPDIR)

cleanall: clean
	$(RM) -r ./build-*

help:
	@echo available targets: all clean cleanall benchmarks

$(BIN): $(OBJS)
	$(LINK.o) $^

$(OBJDIR)/%.o: %.cc
$(OBJDIR)/%.o: %.cc $(DEPDIR)/%.d
	$(PRECOMPILE)
	$(COMPILE.cc) $<
	$(POSTCOMPILE)


.PRECIOUS = $(DEPDIR)/%.d
$(DEPDIR)/%.d: ;

-include $(DEPS)