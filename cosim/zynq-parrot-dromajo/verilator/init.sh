#!/bin/bash
SUITE=$1
PROG=$2
reset
make clean
cp ../$SUITE/$PROG.riscv ../prog.riscv
cp ../$SUITE/$PROG.nbf   ../prog.nbf
../../import/black-parrot-sdk/install/bin/riscv64-unknown-elf-dramfs-objdump -D ../prog.riscv > ../prog.dump
echo "\n\n $SUITE $PROG"
make -B run 2>&1 &> transcript
echo "\n\n $SUITE $PROG"
