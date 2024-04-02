#!/bin/bash

echo "Executing script as: $USER"
echo "$CI_MOUNT_DIR $CI_COMMIT_SHA"

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
git submodule update --init --checkout --recursive cosim/import/black-parrot
git submodule update --init --checkout --recursive cosim/import/black-parrot-subsystems
git submodule update --init --checkout --recursive cosim/import/basejump_stl
git submodule update --init --checkout --recursive cosim/import/bsg_manycore

