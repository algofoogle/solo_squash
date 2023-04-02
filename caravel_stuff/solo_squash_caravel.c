/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>

/*
    Solo Squash init firmware:
    -   Configures MPRJ IO[12:8] as inputs.
    -   Configures MPRJ IO[20:13] as outputs.
    -   If PROJECT_ID is defined: Activates our design as part of a wrapped group submission.
    -   Pulses LA[32] when GPIO config is finished. This is seen via GPIO[20].
*/

// PROJECT_ID of our design if used as part of a Zero to ASIC group submission.
//SMELL: PROJECT_ID (1 to 31?) is assigned by Matt Venn for group submissions,
// but should probably be defined externally to this file (e.g. defined by
// the compilation step) so that this file can remain generic and used in
// other applications without being hardcoded for the wrapped_solo_caravel.
#define PROJECT_ID 1

// #define INPUT_MODE  0x0c02 // The OLD value for PULLUP, no longer considered valid?
// #define INPUT_MODE  GPIO_MODE_USER_STD_INPUT_PULLUP //SMELL: Caravel PULLUP/DOWN might be broken; avoid for now.
#define INPUT_MODE  GPIO_MODE_USER_STD_INPUT_NOPULL

void main()
{
    /* 
    IO Control Registers
    | DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
    | 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |

    Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
    | DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
    | 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
    
     
    Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
    | DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
    | 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |

    */

    // Configure MPRJ IO[12:8] as inputs (optionally with pullups; see INPUT_MODE define above):
    // See also: reg_gpio_pu:
    // https://caravel-docs.readthedocs.io/en/wavedrom-regs/gpio.html
    // https://caravel-harness.readthedocs.io/en/latest/gpio.html
    // ...though it might be outdated??
    // See also: user_defines.v
    reg_mprj_io_8   = INPUT_MODE;                       // ext_reset_n
    reg_mprj_io_9   = INPUT_MODE;                       // pause_n
    reg_mprj_io_10  = INPUT_MODE;                       // new_game_n
    reg_mprj_io_11  = INPUT_MODE;                       // down_key_n
    reg_mprj_io_12  = INPUT_MODE;                       // up_key_n
    // Configure MPRJ IO[18:13] as outputs:
    reg_mprj_io_13  = GPIO_MODE_USER_STD_OUTPUT;        // red
    reg_mprj_io_14  = GPIO_MODE_USER_STD_OUTPUT;        // green
    reg_mprj_io_15  = GPIO_MODE_USER_STD_OUTPUT;        // blue
    reg_mprj_io_16  = GPIO_MODE_USER_STD_OUTPUT;        // hsync
    reg_mprj_io_17  = GPIO_MODE_USER_STD_OUTPUT;        // vsync
    reg_mprj_io_18  = GPIO_MODE_USER_STD_OUTPUT;        // speaker
    // These are also outputs, but just for testing:
    reg_mprj_io_19  = GPIO_MODE_USER_STD_OUTPUT;        // design_reset
    reg_mprj_io_20  = GPIO_MODE_USER_STD_OUTPUT;        // gpio_ready

    // Kick off the very long bit shift process into the GPIO control registers...
    reg_mprj_xfer = 1;
    // ...and wait for the transfer to finish. The clock takes care of this:
    while (reg_mprj_xfer == 1);
    // Note that this completes pretty quickly (I think 13*38 clocks),
    // compared with all the other code above which has to be executed in place (XIP)
    // from relatively slow Flash SPI serial reads.

#ifdef PROJECT_ID // For wrapped group submissions in Zero to ASIC course.
    // activate the project with 1st bank of the LA
    reg_la0_iena = 0;           // Active high; 0 means "disable" input.
    reg_la0_oenb = 0xffffffff;  // Active high (see above); enable all outputs in bank 0 of LA.
    reg_la0_data = 1 << PROJECT_ID; // Activate: Assert LA bit corresponding to our project's "active" line.
#endif

    // Pulse la_data_in[32] (LSB of 2nd bank of LA) to show that GPIOs are now active:
    reg_la1_iena = 0;           // Active high; 0 means "disable" input.
    reg_la1_oenb = 0xffffffff;	// Active high (despite 'b' normally meaning AL); 1 means "enable" output.
                                // This was changed in the era of Litex/VexRiscv, I think, but the name was retained.
                                // NOTE: Could I just set this to 1 since I'm actually just using the LSB?
    reg_la1_data = 1;           // Bit 0 goes high...
    reg_la1_data = 0;           // ...and low again.
    //NOTE: This goes back out via GPIO[20], and can be used both for physical testing/debugging,
    // and also for our tests to sync.

    // This CPU will now hang, while the actual ASIC design is free-running.
}

