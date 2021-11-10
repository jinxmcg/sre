#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -eu

switch_k8s_context
apply_manifests camunda.yml "Deploying Camunda Engine"
wait_for_camunda_deployment || log_fail "Couldn't wait for Camunda Engine to start"
