# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


### This Makefile is to be used inside (say) verilog/dv/solo_squash_caravel
### and its purpose is to run tests of our design, within Caravel,
### via cocotb.

# Note the following things that are used below:
# *	-f$(VERILOG_PATH)/includes/includes.rtl.caravel
#	This is typically caravel_user_project/mgmt_core_wrapper/verilog/includes/includes.rtl.caravel
#	and is the main list of caravel components (heaps of them).
# * make coco_test
#	Runs RTL tests using cocotb and iverilog.
 
PWDD := $(shell pwd)
BLOCKS := $(shell basename $(PWDD))

UNIT_DELAY ?= 1
SIM ?= rtl

# ---- Include Partitioned Makefiles ----

CONFIG = caravel_user_project

# For cocotb tests:
# This is here in case we want to import anyting from the base solo_squash tests:
export PYTHONPATH := $(DESIGNS)/verilog/rtl/solo_squash/test
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)
export COCOTB_REDUCED_LOG_FMT=1

# File(s) to preserve if make fails or is otherwise aborted:
.PRECIOUS: solo_squash_caravel.vcd

# Standard Caravel test environment stuff:
include $(MCW_ROOT)/verilog/dv/make/env.makefile
include $(MCW_ROOT)/verilog/dv/make/var.makefile
include $(MCW_ROOT)/verilog/dv/make/cpu.makefile
include $(MCW_ROOT)/verilog/dv/make/sim.makefile

# Our standard cocotb tests (either RTL or GL depending on $SIM):
coco_test: solo_squash_caravel.hex
	rm -rf sim_build/
	mkdir sim_build/

# Build iverilog-based testbench runner:
	echo "Using UNIT_DELAY=#$(UNIT_DELAY)"
	echo "SIM=$(SIM)"
	time iverilog -Ttyp -DFUNCTIONAL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#$(UNIT_DELAY) \
	-f$(VERILOG_PATH)/includes/includes.rtl.caravel \
	-f$(USER_PROJECT_VERILOG)/includes/includes.$(SIM).$(CONFIG) \
	-o sim_build/sim.vvp \
	solo_squash_caravel_tb.v

# Run test: external reset
	TESTCASE=test_start,test_external_reset MODULE=test_solo_squash_caravel \
	time vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml

# Run test: generate first full frame
	TESTCASE=test_start,test_frame0 MODULE=test_solo_squash_caravel \
	time vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml
#NOTE: You could drop TESTCASE env, in which case all tagged tests will run in order.

	mv solo_squash_caravel.vcd $(SIM)-solo_squash_caravel.vcd

show_results:
	gtkwave $(SIM)-solo_squash_caravel.vcd solo_squash3.gtkw
