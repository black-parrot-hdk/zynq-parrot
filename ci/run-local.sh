#!/bin/bash
source $(dirname $0)/common/functions.sh

# initializing logging
export JOB_LOG="/tmp/ci-local-log/myjob.log"
export JOB_OUT="/tmp/ci-local-out/myjob.out"
export JOB_RPT="/tmp/ci-local-rpt/myjob.rpt"
export JOB_LOGLEVEL="3"
export JOB_IS_LOCAL="1"

export BP_RTL_INSTALL_DIR="$(git rev-parse --show-toplevel)/import/black-parrot/install"
export BP_TOOLS_INSTALL_DIR="$(git rev-parse --show-toplevel)/import/black-parrot-tools/install"
export BP_SDK_INSTALL_DIR="$(git rev-parse --show-toplevel)/import/black-parrot-sdk/install"
export BP_RISCV_DIR="$(git rev-parse --show-toplevel)/import/black-parrot-sdk/riscv"
export DOCKER_PLATFORM="local"
export CONTAINER_IMAGE="local"

# Run the CI script
$(dirname $0)/common/run-ci.sh "$@"

