#!/bin/bash

if [ -z "$CI_MOUNT_DIR" ]
then
  echo "CI_MOUNT_DIR not set; exiting"
  exit -1
else
  echo "CI_MOUNT_DIR set to $CI_MOUNT_DIR"
fi
echo "Cleaning mount"
rm -rf $CI_MOUNT_DIR/*

echo "Checking out commit: $CI_COMMIT_SHA"
git clone https://github.com/black-parrot-hdk/zynq-parrot.git $CI_MOUNT_DIR/zynq-parrot
cd $CI_MOUNT_DIR/zynq-parrot
git checkout $CI_COMMIT_SHA

# Copying collateral
cp $CI_MISC_DIR/simple_bd_1.pynqz2.tar.xz.b64 $CI_MOUNT_DIR/zynq-parrot/cosim/simple-example/simple_bd_1.pynqz2.tar.xz.b64
cp $CI_MISC_DIR/simple_bd_1.ultra96v2.tar.xz.b64 $CI_MOUNT_DIR/zynq-parrot/cosim/simple-example/simple_bd_1.ultra96v2.tar.xz.b64


