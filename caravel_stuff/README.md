<!--
# SPDX-FileCopyrightText: 2023 Anton Maurovic <anton@maurovic.com>
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
# SPDX-License-Identifier: Apache-2.0
-->

# caravel_stuff: Files that are useful for targeting a Caravel-based ASIC

The contents of this folder would be used in many different places. You can try reading [`copy_caravel_stuff.sh`](./copy_caravel_stuff.sh) for a bit of a clue.

The contents of this folder include:

*   `config.json`: This would go in `caravel_user_project/openlane/solo_squash_caravel` and is the OpenLane config for our design.
*   `copy_caravel_stuff.sh`: Attempts to copy all of the files in this directory into their respective locations in the `caravel_user_project`. Note that this might be somewhat specific to the Zero to ASIC course.
*   `CUP-README.md`: README.md for our Caravel project submission, based on [the template](https://github.com/efabless/caravel_user_project/blob/main/README.md).
*   `includes.rtl.caravel_user_project`: Replaces the example in `$DESIGNS/verilog/includes/` and specifies Verilog files that make up the total UPW and design.
*   `klayout_gds.xml`: Layer Properties file that can be used with KLayout's `-l` option to display GDS layers the way Anton likes them. NOTE: To make it a bit easier to see pin names, you might need to do the following: (1) ensure `met2.label` layer is visible (top and bottom pins); (2) ensure `met3.label` layer is visible (left and right pins); (3) Go to File &rarr; Setup &rarr; Display &rarr; Texts and choose "Times Italic", "Auto" color, text size "2" micron, turn *off* "Apply text scaling and rotation"; (4) optionally turn on View &rarr; Show Layers Without Fill.
*   `macro.cfg`: Would normally be called `caravel_user_project/openlane/user_project_wrapper/macro.cfg`: 1-line file specifying the name of our design "macro" (i.e. pre-built layout) and where it should be placed in the user project area.
*   `Makefile`: to be used inside (say) `verilog/dv/solo_squash_caravel` to run tests of our design via cocotb.
*   `solo_squash_caravel_tb.v`: A testbench to be used with cocotb for testing within Caravel (i.e. via `uut`, which I think wraps the UPW). This would normally go in the Caravel project's `verilog/rtl/dv/`.
*   `solo_squash_caravel.c`: VexRiscv firmware to configure GPIOs for our design.
*   `solo_squash*.gtkw`: GTKWave "Save Files" that can just be used to visualise any of our design's generated `*.vcd` files in a particular way. Mostly just for convenience.
*   `test_solo_squash_caravel.py`: Tests that are specific to our design when used in Caravel, to be used inside (say) `verilog/dv/solo_squash_caravel`. Ideally should follow the solo_squash repo's `test/test_solo_squash.py` closely, but it's probably a WIP right now that's all over the place.
*   `UPW-config.json`: Would normally be called `caravel_user_project/openlane/user_project_wrapper/config.json` and instantiates our design's GDS inside the Caravel harness.
*   `user_defines.v`: Copy of `caravel_user_project/rtl/user_defines.v`, specifying the power-on state of GPIOs even before the SoC firmware configures GPIOs.
*   `user_project_wrapper.v`: UPW that could be used for this design, which instantiates our "adapter" `solo_squash_caravel`.
*   `wrapped_project_id.h`: This file has no code. It has [an alternate in `wrapped_stuff`](../wrapped_stuff/wrapped_project_id.h) which defines `PROJECT_ID` for use in a wrapped group submission, but the copy in this directory is just a dummy file that lets the firmware compile for stand-alone-design mode.
*   `docs/solo_squash_upw.png`: Some eye-candy: Hand-built image (using screenshots made by KLayout) to show the overall UPW design, and then close-ups. This is intended to go into `caravel_user_project/docs/` and then be used in `caravel_user_project/README.md`.
