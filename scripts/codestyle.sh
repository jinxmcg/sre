#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -e

log_test "Running a linter for your code"
make -C "${SCRIPTPATH}/../autoscaler-${AUTOSCALER_LANGUAGE}" lint && log_pass "Code linting passed" || log_warn "Linting issues detected"
