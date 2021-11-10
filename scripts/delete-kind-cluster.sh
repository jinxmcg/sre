#!/bin/bash

# WARNING: You don't need to edit this file!

# Deletes a kind cluster and its registry

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -e

DELETE_CLUSTER=$(yes_no "Do you want to delete kind cluster and all resources in it?")

if [[ "$DELETE_CLUSTER" == "y" ]]; then
  log_info "Deleting kind cluster [$CLUSTER_NAME]"
  kind delete cluster --name="$CLUSTER_NAME"
else
  log_info "Skipping cluster deletion"
fi
