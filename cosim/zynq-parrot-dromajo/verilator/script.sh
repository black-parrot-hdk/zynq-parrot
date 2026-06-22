#!/bin/bash
echo "run me with a command line argument specifying the test suite to run; example: ./script.sh riscv-tests"
SUITE=$1
mkdir $SUITE

for f in ../$SUITE/*.riscv;
do FILENAME=$(basename $f .riscv);
cp ../$SUITE/$FILENAME.riscv ../prog.riscv;
cp ../$SUITE/$FILENAME.nbf   ../prog.nbf;
echo "\n\nRunning $FILENAME.riscv"
make run 2>&1 1> $SUITE/$FILENAME.log
echo "\n\nDone running $FILENAME.riscv"
done
