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


### This Makefile is to be used inside (say) verilog/dv/solo_squash
### and its purpose is to run tests of our design, within Caravel,
### via cocotb.

 
PWDD := $(shell pwd)
BLOCKS := $(shell basename $(PWDD))

# ---- Include Partitioned Makefiles ----

CONFIG = caravel_user_project

# For cocotb tests:
#SMELL: This PYTHONPATH is clearly wrong, but is it used anyway?
# Maybe it's only needed if we have to import other modules (as rgb_mixer does with, say, Encoder).
export PYTHONPATH := $(DESIGNS)/verilog/rtl/wrapped_rgb_mixer/rgb_mixer/test
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)
export COCOTB_REDUCED_LOG_FMT=1

# Standard Caravel test environment stuff:
include $(MCW_ROOT)/verilog/dv/make/env.makefile
include $(MCW_ROOT)/verilog/dv/make/var.makefile
include $(MCW_ROOT)/verilog/dv/make/cpu.makefile
include $(MCW_ROOT)/verilog/dv/make/sim.makefile

# Our cocotb tests:
coco_test: solo_squash.hex
	rm -rf sim_build/
	mkdir sim_build/

	iverilog -Ttyp -DFUNCTIONAL -DSIM -DUSE_POWER_PINS -DUNIT_DELAY=#1 \
	-f$(VERILOG_PATH)/includes/includes.rtl.caravel \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.$(CONFIG) \
	-o sim_build/sim.vvp \
	solo_squash_tb.v

	MODULE=test_solo_squash \
	vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml
#NOTE: Besides MODULE, test can also be prefixed with a comma-separated
# list of specific tests to be run in order, like this:
# TESTCASE=test_start,test_frame0

show_results:
	gtkwave solo_squash.vcd solo_squash3.gtkw
