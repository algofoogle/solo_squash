# caravel_stuff: Files that are useful for targeting a Caravel-based ASIC

The contents of this folder would be used in many different places. You can try reading [`copy_caravel_stuff.sh`](./copy_caravel_stuff.sh) for a bit of a clue.

The contents of this folder include:

*   `config.json`: This would go in `caravel_user_project/openlane/solo_squash` and is the OpenLane config for our design.
*   `copy_caravel_stuff.sh`: Attempts to copy all of the files in this directory into their respective locations in the `caravel_user_project`. Note that this might be somewhat specific to the Zero to ASIC course.
*   `CUP-README.md`: README.md for our Caravel project submission, based on [the template](https://github.com/efabless/caravel_user_project/blob/main/README.md).
*   `includes.rtl.caravel_user_project`: Replaces the example in `$DESIGNS/verilog/includes/` and specifies Verilog files that make up the total UPW and design.
*   `klayout_gds.xml`: Layer Properties file that can be used with KLayout's `-l` option to display GDS layers the way Anton likes them. NOTE: To make it a bit easier to see pin names, you might need to do the following: (1) ensure `met2.label` layer is visible (top and bottom pins); (2) ensure `met3.label` layer is visible (left and right pins); (3) Go to File &rarr; Setup &rarr; Display &rarr; Texts and choose "Times Italic", "Auto" color, text size "2" micron, turn *off* "Apply text scaling and rotation"; (4) optionally turn on View &rarr; Show Layers Without Fill.
*   `macro.cfg`: Would normally be called `caravel_user_project/openlane/user_project_wrapper/macro.cfg`: 1-line file specifying the name of our design "macro" (i.e. pre-built layout) and where it should be placed in the user project area.
*   `Makefile`: to be used inside (say) `verilog/dv/solo_squash` to run tests of our design via cocotb.
*   `solo_squash_tb.v`: A testbench to be used with cocotb for testing within Caravel (i.e. via `uut`, which I think wraps the UPW). This would normally go in the Caravel project's `verilog/rtl/dv/`.
*   `solo_squash.c`: VexRiscv firmware to configure GPIOs for our design.
*   `solo_squash*.gtkw`: GTKWave "Save Files" that can just be used to visualise any of our design's generated `*.vcd` files in a particular way. Mostly just for convenience.
*   `test_solo_squash.py`: Tests that are specific to our design when used in Caravel, to be used inside (say) `verilog/dv/solo_squash`. Ideally should follow `test/test_solo_squash.py` closely, but it's probably a WIP right now that's all over the place.
*   `UPW-config.json`: Would normally be called `caravel_user_project/openlane/user_project_wrapper/config.json` and instantiates our design's GDS inside the Caravel harness.
*   `user_project_wrapper.v`: UPW that could be used for this design, which instantiates our "adapter" `solo_squash_caravel`.
