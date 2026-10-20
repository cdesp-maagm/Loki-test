#! /usr/bin/env bash

FILES=boot.bin
TARGET=../../hdl/projects
SUBDIRS=$(find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n')

for f in $FILES; do
    for d in $SUBDIRS; do
        rm -f $d/$f
        ln -s $TARGET/$d/build/$f $d/$f
    done
done

