#!/bin/bash
echo "run me with a command line argument specifying the test suite to run; example: ./script.sh riscv-tests"
SUITE=$1
mkdir logs

for f in ../$SUITE/*.riscv;
do FILENAME=$(basename $f .riscv);
cp ../$SUITE/$FILENAME.riscv ../prog.riscv;
cp ../$SUITE/$FILENAME.nbf   ../prog.nbf;
echo "\n\nRunning $FILENAME.riscv"
make run 2>&1 1> logs/$FILENAME.log
echo "\n\nDone running $FILENAME.riscv"
# sleep 1
# read input </dev/tty;

fail=$(grep -cE "FAIL" logs/$FILENAME.log)
if [[ $fail -gt 0 ]]
then
  mv logs/$FILENAME.log logs/FAIL_$FILENAME.log
fi

pass=$(grep -c "PASS" logs/$FILENAME.log)
if [[ $pass -gt 0 ]]
then
  echo $FILENAME >> stats
  grep -B 11 MIPS logs/$FILENAME.log | tee -a stats
  mv logs/$FILENAME.log logs/PASS_$FILENAME.log
fi
reset;
done
