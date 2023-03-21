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


# This script copies the files found here in caravel_stuff/ into the respective
# locations they need to be inside caravel_user_project.

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

ok () { printf "${GREEN}_ OK _${NC}\n"; }
bad () { printf "${RED}_ BAD _${NC}\n"; }

if [ -z "$DESIGNS" ]; then
    echo "\$DESIGNS isn't set. Normally it would point to something like:"
    echo "  ~/asic_tools/caravel_user_project"
    bad
    exit 1
elif [ ! -d "$DESIGNS" ]; then
    echo "\$DESIGNS doesn't refer to a valid directory. Normally it would point to something like:"
    echo "  ~/asic_tools/caravel_user_project"
    echo "...but it is currently set to: '$DESIGNS'"
    bad
    exit 1
fi

export BACKUP_SUFFIX="-backup-$(date +%s)"

backup_target () {
    if [ -f "$1" ]; then
        TT="$1$BACKUP_SUFFIX"
        echo -n "$1 already exists; backing up as: $TT "
        mv $1 $TT && ok || bad
    fi
}

SS=$DESIGNS/verilog/dv/solo_squash_caravel
mkdir -p $SS
cp -v Makefile $SS/ && ok || bad
cp -v solo_squash* $SS/ && ok || bad
cp -v test_solo_squash_caravel.py $SS/ && ok || bad

T="$DESIGNS/verilog/rtl/user_project_wrapper.v"
backup_target $T
cp -v user_project_wrapper.v $T && ok || bad

cp -v includes.rtl.caravel_user_project $DESIGNS/verilog/includes/ && ok || bad

mkdir -p $DESIGNS/openlane/solo_squash_caravel
cp -v config.json $DESIGNS/openlane/solo_squash_caravel && ok || bad

# klayout_gds.xml -- This can just stay in caravel_stuff for now.

T="$DESIGNS/openlane/user_project_wrapper/config.json"
backup_target $T
cp -v UPW-config.json $T && ok || bad

T="$DESIGNS/openlane/user_project_wrapper/macro.cfg"
backup_target $T
cp -v macro.cfg $T && ok || bad

T="$DESIGNS/README.md"
backup_target $T
cp -v CUP-README.md $T && ok || bad

T="$DESIGNS/verilog/rtl/user_defines.v"
backup_target $t
cp -v user_defines.v $T && ok || bad

mkdir -p $DESIGNS/docs
cp -v docs/solo_squash_upw.png $DESIGNS/docs/ && ok || bad
