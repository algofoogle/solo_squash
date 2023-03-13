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
	-	Configures MPRJ IO[12:8] as inputs
	-	Configures MPRJ IO[18:13] as outputs
*/

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

	// Configure MPRJ IO[12:8] as inputs without pullups:
	reg_mprj_io_8	= GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_9	= GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_10	= GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_11	= GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_12	= GPIO_MODE_USER_STD_INPUT_NOPULL;
	// Configure MPRJ IO[18:13] as outputs:
	reg_mprj_io_13	= GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_14	= GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_15	= GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_16	= GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_17	= GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_18	= GPIO_MODE_USER_STD_OUTPUT;

	// Kick off the very long bit shift process into the GPIO control registers...
	reg_mprj_xfer = 1;
	// ...and wait for the transfer to finish. The clock takes care of this:
	while (reg_mprj_xfer == 1);
}

