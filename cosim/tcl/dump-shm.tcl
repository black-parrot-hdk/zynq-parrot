database -open dump -shm
probe -create bsg_nonsynth_zynq_testbench -depth all -all -shm -database dump
run
