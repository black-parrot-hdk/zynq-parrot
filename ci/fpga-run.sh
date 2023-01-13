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
echo "Setting up Pynq Z2"
cp cosim/${BASENAME}-example/{${BASENAME}_bd_1.pynqz2.tar.xz.b64,${BASENAME}_bd_1.tar.xz.b64}
echo "Unpacking bitstream"
make -C cosim/${BASENAME}-example/fpga clean unpack_bitstream
echo "Loading bitstream"
make -C cosim/${BASENAME}-example/fpga load_bitstream
echo "Running test"
make -C cosim/${BASENAME}-example/fpga run
echo "Unmounting current mount"
sudo umount -f /home/xilinx/mnt

exit 0

