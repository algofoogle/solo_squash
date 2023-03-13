#!/usr/bin/bash

# This script copies the files found here in caravel_stuff/ into the respective
# locations they need to be inside caravel_user_project.

if [ -z "$DESIGNS" ]; then
    echo "\$DESIGNS isn't set. Normally it would point to something like:"
    echo "~/asic_tools/caravel_user_project"
    exit 1
fi

SS=$DESIGNS/verilog/dv/solo_squash
mkdir -p $SS
cp -v Makefile $SS/
cp -v solo_squash* $SS/
cp -v test_solo_squash.py $SS/

T="$DESIGNS/verilog/rtl/user_project_wrapper.v"
if [ -f "$T" ]; then
    TT="$T-backup-$(date +%s)"
    echo "$T already exists; backing up as: $TT"
    mv $T $TT
fi
cp -v user_project_wrapper.v $T

cp -v includes.rtl.caravel_user_project $DESIGNS/verilog/includes/
