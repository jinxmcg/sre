#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -eu

N_PROCESS_STARTED=${1:-0}  # 0 - default value for N_PROCESS_STARTED if not specified

switch_k8s_context
apply_manifests process-starter.yml "Deploying Camunda Process Starter"
adjust_process_starter "$N_PROCESS_STARTED"
wait_for_process_starter || log_fail "Couldn't wait for Process Starter to start"
