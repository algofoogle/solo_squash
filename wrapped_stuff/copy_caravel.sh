#!/usr/bin/bash

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


# This script should be run from within
# caravel_user_project/verilog/rtl/solo_squash/wrapped_stuff
# (when that repo is in a branch to be used just for testing this
# wrapper directly inside a caravel context) it will attempt to install
# stuff that repo, allowing for testing of the wrapper
# (i.e. what will become verilog/rtl/wrapper.v).


  RED='\033[0;31m'
GREEN='\033[0;32m'
   NC='\033[0m' # No Color
ok () { printf "${GREEN}_ OK _${NC}\n"; }
bad () { printf "${RED}_ BAD _${NC}\n"; }

WT=../..
DV=../../../dv
if [ ! -d "$DV" ]; then
    echo "ERROR: Aborting because $DV doesn't seem to exist as a directory"
    exit 1
fi
CT=$DV/solo_squash_caravel
mkdir -p $CT

# Copy test files:
CS=../caravel_stuff                         && ok || bad
cp -v wrapped_project_id.h $CT/             && ok || bad
cp -v $CS/Makefile $CT/                     && ok || bad
cp -v $CS/solo_squash* $CT/                 && ok || bad
cp -v $CS/test_solo_squash_caravel.py $CT/  && ok || bad
# Make sure .gitignore exists and contains an EXCEPTION to permit *.gtkw
fgrep '!*.gtkw' $SS/.gitignore 2>/dev/null || echo '!*.gtkw' >> $SS/.gitignore

# Copy caravel build files:
V=../../..
RTL=$V/rtl
cp -v includes.rtl.caravel_user_project $V/includes && ok || bad
cp -v wrapper.v $RTL/                               && ok || bad
cp -v user_project_wrapper.v $RTL/                  && ok || bad
