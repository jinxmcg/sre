#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -eu

switch_k8s_context
apply_manifests autoscaler.yml "Deploying Camunda Deployment Autoscaler"
restart_rollout camunda-autoscaler
wait_for_autoscaler || log_fail "Couldn't wait for autoscaler to start"
