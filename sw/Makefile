# from https://gist.github.com/maxtruxa/4b3929e118914ccef057f8a05c614b0f

# output binary
BIN := abr-parser

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
CXXFLAGS :=
# C/C++ flags
CPPFLAGS := -g -Wall -pedantic -fopenmp
# linker flags
LDFLAGS := -fopenmp
# flags required for dependency generation; passed to compilers
DEPFLAGS = -I /usr/lib/boost/boost_1_70_0/ -MT $@ -MD -MP -MF $(DEPDIR)/$*.Td

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
	./$(BIN) -d build-mct_h2Asc -r ../data/mct_rules.csv -s 4 >> build-mct_h2Asc/log.txt
	./$(BIN) -d build-mct_h2Des -r ../data/mct_rules.csv -s 5 >> build-mct_h2Des/log.txt
	./$(BIN) -d build-zrh_h2Des -r ../data/mct_rules-zrh.csv -s 5 >> build-zrh_h2Des/log.txt

clean:
	$(RM) -r $(OBJDIR) $(DEPDIR)

cleanall:
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