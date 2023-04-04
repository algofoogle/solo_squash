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


# This script should be run from within wrapped_solo_squash/solo_squash/wrapped_stuff
# and it will attempt to install stuff into wrapped_solo_squash and
# wrapped_solo_squash/caravel_test


  RED='\033[0;31m'
GREEN='\033[0;32m'
   NC='\033[0m' # No Color
ok () { printf "${GREEN}_ OK _${NC}\n"; }
bad () { printf "${RED}_ BAD _${NC}\n"; }

WT=../..
CT=../../caravel_test
if [ ! -d "$CT" ]; then
    echo "ERROR: Aborting because $CT doesn't seem to exist as a directory"
    exit 1
fi

# Copy base files:
cp -v properties.sby $WT/                   && ok || bad
cp -v wrapper.v $WT/                        && ok || bad
cp -v wrapped-config.json $WT/config.json   && ok || bad
cp -v wrapped-README.md $WT/README.md       && ok || bad

# Copy test files:
CS=../caravel_stuff                         && ok || bad
cp -v wrapped_project_id.h $CT/             && ok || bad
cp -v caravel_test-README.md $CT/README.md  && ok || bad
cp -v $CS/Makefile $CT/                     && ok || bad
cp -v $CS/solo_squash* $CT/                 && ok || bad
cp -v $CS/test_solo_squash_caravel.py $CT/  && ok || bad
