# This is inspired by: https://github.com/mattvenn/rgb_mixer/blob/main/Makefile

# Main Verilog sources for our design:
MAIN_VSOURCES = src/solo_squash.v

# Verilog sources used for testing:
TEST_VSOURCES = test/dump_vcd.v

# Top Verilog module representing our design:
TOP = solo_squash


# Stuff for simulation:
SIM_LDFLAGS = -lSDL2 -lSDL2_ttf
SIM_EXE = sim/obj_dir/V$(TOP)
XDEFINES := $(DEF:%=+define+%)
# A fixed seed value for sim_seed:
SEED ?= 22860
# A random seed value for im_random:
RSEED := $(shell bash -c 'echo $$RANDOM')


# COCOTB variables:
export COCOTB_REDUCED_LOG_FMT=1
export PYTHONPATH := test:$(PYTHONPATH)
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

# Common iverilog args we might end up using:
# -Ttyp 			= One of min:typ:max; use typ (typical) time parameters for device characteristics?
# -o whatever.vvp	= Output compiled iverilog file that will run inside the vvp virtual machine
# -sTOPMODULE		= Top module is named TOPMODULE
# -DFUNCTIONAL		= FUNCTIONAL define passes to sky130 models/primitives?
# -DSIM				= SIM define; what uses it?
# -DUSE_POWER_PINS	= USE_POWER_PINS define; used by design and sky130 models/primitives?
# -DUNIT_DELAY=#1	= Define default propagation delay (?) of models to be 1ns...?
# -fLISTFILE		= (can be specified multiple times) LISTFILE contains a newline-separated list of other .v files to compile
# -g2012			= Support Verilog generation IEEE1800-2012.

# Test the design using iverilog and our cocotb tests...
# For this main test, we use two top modules (hence -s twice):
# solo_squash (the design) and dump_vcd (just to ensure we get a .vcd file).
test:
	rm -rf sim_build
	mkdir sim_build
	rm -rf results
	iverilog \
		-g2012 \
		-o sim_build/sim.vvp \
		-s solo_squash -s dump_vcd \
		$(MAIN_VSOURCES) $(TEST_VSOURCES)
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_solo_squash \
		vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus \
		sim_build/sim.vvp
	mkdir results
	mv results.xml results/
	mv solo_squash.vcd results/
	! grep -i failure results/results.xml
#SMELL: Is there a better way to tell iverilog, vvp, or cocotb to write
# results directly into results?


show_results:
	gtkwave results/solo_squash.vcd solo_squash.gtkw


# Simulate our design visually using Verilator, outputting to an SDL2 window.
#NOTE: All unassigned bits are set to 0:
sim: $(SIM_EXE)
	@$(SIM_EXE)

# Simulate with all unassigned bits set to 1:
sim_ones: $(SIM_EXE)
	@$(SIM_EXE) +verilator+rand+reset+1

# Simulate with unassigned bits fully randomised each time:
sim_random: $(SIM_EXE)
	echo "Random seed: " $(RSEED)
	@$(SIM_EXE) +verilator+rand+reset+2 +verilator+seed+$(RSEED)

# Simulate with unassigned bits randomised based on a known seed each time:
sim_seed: $(SIM_EXE)
	echo "Random seed: " $(SEED)
	@$(SIM_EXE) +verilator+rand+reset+2 +verilator+seed+$(SEED)


#SMELL: Should this depend on sim/sim_main.cpp? What about also $(MAIN_VSOURCES)?
$(SIM_EXE):
	verilator \
		--Mdir sim/obj_dir \
		--cc $(MAIN_VSOURCES) \
		--top-module $(TOP) \
		--exe --build ../sim/sim_main.cpp \
		-CFLAGS -DINSPECT_INTERNAL\
		-LDFLAGS "$(SIM_LDFLAGS)" \
		+define+RESET_AL \
		$(XDEFINES)

clean:
	rm -rf sim_build
	rm -rf results
	rm -rf sim/obj_dir
	rm -rf test/__pycache__
	rm -rf solo_squash.vcd results.xml

# This tells make that 'test' and 'clean' are themselves not artefacts to make,
# but rather tasks to always run:
.PHONY: test clean sim sim_ones sim_random sim_seed show_results

