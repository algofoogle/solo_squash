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
ALERT='\033[0;93m' # Bright yellow.
   NC='\033[0m' # No Color
ok () { printf "${GREEN}_ OK _${NC}\n"; }
bad () { printf "${RED}_ BAD _${NC}\n"; }
err () { printf "${RED}ERROR${NC}: "; }

# wrapped_* base dir:
TS=$(date +"%Y%m%d_%H%M%S")
WT=../..

# Make sure $WT refers to a valid wrapped_* repo:
if [ ! -f $WT/info.yaml ] || ! fgrep 'caravel_test:' $WT/info.yaml 2>/dev/null 1>&2; then
  err; echo "Aborting because this doesn't seem to be inside a valid wrapped repo"
  echo "(could not find a file called $WT/info.yaml containing 'caravel_test:')"
  exit 1
fi

# Target directory we want the tests to live in, within the wrapped_* repo.
SSC=$WT/solo_squash_caravel

# Ensure target directory exists:
if [ -d "$SSC" ]; then
  echo "$SSC exists; files will be updated"
elif [ -d "$WT/caravel_test" ]; then
  echo "$WT/caravel_test exists..."
  echo -e "${ALERT}...you should consider deleting it with:  git rm -rf caravel_test${NC}"
  echo "We will now create $SSC and put the test files in there."
  mkdir -p $SSC
else
  echo -e "${ALERT}WARNING${NC}: Neither $SSC nor $WT/caravel_test exist."
  echo "If you proceed, $SSC will be created and populated with the test files anyway."
  read -p "Press ENTER to continue, or CTRL+C to abort:"
  mkdir -p $SSC
fi


# Copy base files:
cp -v properties.sby $WT/                   && ok || bad
cp -v wrapper.v $WT/                        && ok || bad
cp -v wrapped-config.json $WT/config.json   && ok || bad
cp -v wrapped-README.md $WT/README.md       && ok || bad

# Copy test files:
CS=../caravel_stuff                         && ok || bad
cp -v wrapped_project_id.h $SSC/            && ok || bad
cp -v caravel_test-README.md $SSC/README.md && ok || bad
cp -v $CS/Makefile $SSC/                    && ok || bad
cp -v $CS/solo_squash* $SSC/                && ok || bad
cp -v $CS/test_solo_squash_caravel.py $SSC/ && ok || bad
