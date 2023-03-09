# This is inspired by: https://github.com/mattvenn/rgb_mixer/blob/main/Makefile

MAIN_VSOURCES = src/solo_squash.v
TEST_VSOURCES = test/dump_vcd.v

# COCOTB variables
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

# For this main test, we use two top modules (hence -s twice):
# solo_squash (the design) and dump_vcd (just to ensure we get a .vcd file).
test:
	rm -rf sim_build
	mkdir sim_build
	iverilog \
		-g2012 \
		-o sim_build/sim.vvp \
		-s solo_squash -s dump_vcd \
		$(MAIN_VSOURCES) $(TEST_VSOURCES)
#...then to run tests, we can do something like this:
# PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_solo_squash vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
# ! grep failure results.xml
#...or something like this:
# https://github.com/mattvenn/wrapped_rgb_mixer/blob/8134e091d816ef390c96f353831311ba90ed6b76/caravel_rgb_mixer/Makefile#L22-L27

clean:
	rm -rf sim_build

# This tells make that 'test' and 'clean' are themselves not artefacts to make,
# but rather tasks to always run:
.PHONY: test clean

