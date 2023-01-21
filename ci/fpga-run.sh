#!/bin/bash

echo "Executing scripts as: $USER"

echo "Unmounting current mount"
sudo umount -f /home/xilinx/mnt
echo "Re-mounting $CI_LOCAL_IP:$CI_MOUNT_DIR"
sudo mount $CI_LOCAL_IP:$CI_MOUNT_DIR /home/xilinx/mnt
echo "Contents of new mount: /home/xilinx/mnt->$CI_MOUNT_DIR"
ls /home/xilinx/mnt
echo "This must be set up correctly by the prescript"
cd /home/xilinx/mnt/zynq-parrot
echo "Sourcing python environment"
source /etc/profile.d/pynq_venv.sh
echo "Dropping VM"
sudo sh -c "echo 1 > /proc/sys/vm/overcommit_memory"
sudo sh -c "echo 1 > /proc/sys/vm/drop_caches"
echo "Unpacking bitstream"
make -C cosim/${EXAMPLE_NAME}/fpga clean unpack_bitstream BOARDNAME=$BOARDNAME
echo "Loading bitstream and running test"
make -C cosim/${EXAMPLE_NAME}/fpga reset_pl load_bitstream run BOARDNAME=$BOARDNAME NBF_FILE=$NBF_FILE

