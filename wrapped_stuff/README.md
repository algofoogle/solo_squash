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

# wrapped_stuff: Useful files for targeting a wrapped group submission in a Caravel ASIC

This is a counterpart to [`caravel_stuff`](../caravel_stuff/) and provides extra
stuff needed for using our design in a wrapped group submission as part of the
Zero to ASIC course.

It is primarily useful to the [`wrapped_solo_squash` repo](https://github.com/algofoogle/wrapped_solo_squash).


## How do we use this?

*   For use inside the wrapped repo (e.g. [`wrapped_solo_squash` repo](https://github.com/algofoogle/wrapped_solo_squash)), you will do this:
    *   Make sure this repo is a submodule of the wrapped repo; typically in a subdirectory called `solo_squash`.
    *   `cd solo_squash/wrapped_stuff`
    *   `./copy_wrapped.sh`
    *   This should copy the necessary files in higher-up directories of the wrapped repo,
        especially inside `caravel_stuff` and the base dir of the repo.
    *   Maybe try `git status` inside the wrapped repo to see what (if anything) changed.
    *   You would then probably run the tests in `caravel_tests` and try going back to harden with OpenLane:
        *   `cd $OPENLANE_ROOT`
        *   `./flow.tcl -design wrapped_solo_squash`
*   For use inside caravel, you will typically use it inside a clean(ish) `caravel_user_project`, and possibly a dedicated testing branch, just to make sure the wrapper and everything are set up properly.
    *   Make sure this repo is a submodule of the caravel repo, as `verilog/rtl/solo_squash`.
    *   `cd verilog/rtl/solo_squash/caravel_stuff`
    *   `./copy_caravel.sh`
    *   This should copy necessary files throughout caravel.
    *   Maybe try `git status` inside the caravel repo to see what (if anything) changed.
    *   You would then probably run the tests in `verilog/dv/solo_squash`.


## What's in this subdirectory?

NOTE: Most of what's in here is also already built up in [`wrapped_solo_squash`](https://github.com/algofoogle/wrapped_solo_squash). Nevertheless, here are the files that are used to build such a repo:

*   [caravel_test-README.md](./caravel_test-README.md): Will be called `README.md` when placed in `caravel_test` in the wrapped repo.
*   [copy_wrapped.sh](./copy_wrapped.sh): Install these files, and everything else, directly into a wrapped repo, e.g. [`wrapped_solo_squash`](https://github.com/algofoogle/wrapped_solo_squash). Must be run from this subdirectory, within this repo as a submodule of the wrapped repo.
*   [copy_caravel.sh](./copy_caravel.sh): Install these files, and everything else, into a caravel_user_project context, for the purposes of testing the wrapper itself inside caravel.
*   [includes.rtl.caravel_user_project](./includes.rtl.caravel_user_project): Only used by `copy_caravel.sh`; includes source files (inc. `wrapper.v`) when testing the wrapped design inside caravel.
*   [properties.sby](./properties.sby): Goes inside base dir of wrapped repo. Used by `sby` to prove the design's tristate buffers properly detach the design when the active line is not asserted.
*   [user_project_wrapper.v](./user_project_wrapper.v): Caravel user_project_wrapper that is used to directly test our wrapped design inside a caravel context.
*   [wrapped_project_id.h](./wrapped_project_id.h): Normally this file would be rebuilt by the copy script. For normal direct caravel submissions (i.e. no wrapper) it would be blank. Otherwise, it contains just one line to define `PROJECT_ID` (based on what Matt Venn specifies), and it goes into the same directory as wherever the tests are placed (both for the wrapped repo and when testing the wrapper in the context of the caravel user_project_wrapper).
*   [wrapped-config.json](./wrapped-config.json): Goes into base directory of wrapped repo as `config.json`. Parameters for OpenLane to harden our "wrapper".
*   [wrapped-README.md](./wrapped-README.md): Goes into the base directory of the wrapped repo as `README.md`.
*   [wrapper.v](./wrapper.v): Wrapper for our design in a group submission. Goes into base directory of wrapped repo ([`wrapped_project_template`](https://github.com/mattvenn/wrapped_project_template)).
