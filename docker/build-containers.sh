#!/bin/bash

set -e

CONTS="base default devel"

for CONT in $CONTS; do
    (cd $CONT && docker build -t jail:$CONT .)
done
