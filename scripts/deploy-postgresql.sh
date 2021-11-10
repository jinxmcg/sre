#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -eu

switch_k8s_context
apply_manifests postgres.yml "Deploying PostgreSQL for Camunda Engine"
wait_for_postgresql || log_fail "Couldn't get PostgreSQL to start"
