#!/usr/bin/bash

# This script copies the files found here in caravel_stuff/ into the respective
# locations they need to be inside caravel_user_project.

if [ -z "$DESIGNS" ]; then
    echo "\$DESIGNS isn't set. Normally it would point to something like:"
    echo "~/asic_tools/caravel_user_project"
    exit 1
fi

export BACKUP_SUFFIX="-backup-$(date +%s)"

backup_target () {
    if [ -f "$1" ]; then
        TT="$1$BACKUP_SUFFIX"
        echo "$1 already exists; backing up as: $TT"
        mv $1 $TT
    fi
}

SS=$DESIGNS/verilog/dv/solo_squash
mkdir -p $SS
cp -v Makefile $SS/
cp -v solo_squash* $SS/
cp -v test_solo_squash.py $SS/

T="$DESIGNS/verilog/rtl/user_project_wrapper.v"
backup_target $T
cp -v user_project_wrapper.v $T

cp -v includes.rtl.caravel_user_project $DESIGNS/verilog/includes/

mkdir -p $DESIGNS/openlane/solo_squash
cp -v config.json $DESIGNS/openlane/solo_squash

# klayout_gds.xml -- This can just stay in caravel_stuff for now.

T="$DESIGNS/openlane/user_project_wrapper/config.json"
backup_target $T
cp -v UPW-config.json $T

T="$DESIGNS/openlane/user_project_wrapper/macro.cfg"
backup_target $T
cp -v macro.cfg $T

T="$DESIGNS/README.md"
backup_target $T
cp -v CUP-README.md $T
