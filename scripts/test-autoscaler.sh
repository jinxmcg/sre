#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=$(realpath $0)
SCRIPTPATH=$(dirname $SCRIPT)

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -eu

function test_scale_operation() {
  PROCESS_CREATION_RATE=$1
  EXPECTED_REPLICAS=$2
  TIMEOUT=$3
  log_test "When process creation rate is ${PROCESS_CREATION_RATE}, expect Camunda Engine scaled to ${EXPECTED_REPLICAS} replicas (timeout: ${TIMEOUT}s)"
  "${SCRIPTPATH}/deploy-process-starter.sh" "${PROCESS_CREATION_RATE}"

  wait_for_camunda_replica_count "${EXPECTED_REPLICAS}" "${TIMEOUT}" && log_pass "Replica count matched expecations" || log_fail "Replica count did not match expecations"
}

switch_k8s_context

test_scale_operation 120 3 180
wait_for_camunda_deployment
log_separator

test_scale_operation 500 4 180
wait_for_camunda_deployment
log_separator

test_scale_operation 5 1 180
wait_for_camunda_deployment
log_separator
