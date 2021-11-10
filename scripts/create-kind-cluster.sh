#!/bin/bash

# WARNING: You don't need to edit this file!

# Creates a kind cluster
# Cluster is bootstraped with a Docker registry (localhost:5555) and can use locally pushed images

SCRIPT=$(realpath $0)
SCRIPTPATH=$(dirname $SCRIPT)

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -eo errexit

function create_cluster() {
  kind create cluster --name="$CLUSTER_NAME"
}

kind get clusters | grep "$CLUSTER_NAME" && CLUSTER_EXISTS=true || CLUSTER_EXISTS=false

if [[ $CLUSTER_EXISTS == "false" ]]; then
  create_cluster
fi
