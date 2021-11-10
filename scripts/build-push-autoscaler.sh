#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -e

AUTOSCALER_DIR="${SCRIPTPATH}/../autoscaler-${AUTOSCALER_LANGUAGE}"

log_test "Applying code formatter to your autoscaler's code"
make -C "${AUTOSCALER_DIR}" fmt && log_pass "Autoformatted successfully" || ( log_warn "Could not autoformat the code" )

log_test "Running linter for your Dockerfile"
make -C "${AUTOSCALER_DIR}" dockerfile-lint && log_pass "Dockerfile lint check passed" || ( log_warn "Dockerfile lint check did not pass" )

log_test "Building Docker image of your autoscaler"
echo make -C "${AUTOSCALER_DIR}" build CLUSTER="${CLUSTER_NAME}"
make -C "${AUTOSCALER_DIR}" build && log_pass "Build and tagged successfully" || ( log_fail "Could not build and tag docker image" ; exit 1 )

log_test "Pushing Docker image of your autoscaler to local kind registry"
make -C "${AUTOSCALER_DIR}" push CLUSTER="${CLUSTER_NAME}" && log_pass "Pushed successfully" || ( log_fail "Could not push docker image" ; exit 1 )
