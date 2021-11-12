#!/bin/bash

# WARNING: You don't need to edit this file!

BOLD='\033[1m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

function yes_no() {
  PROMPT="$1"
  read -p "$1 (y/n) " RESP

  while [[ "$RESP" != "y" ]] && [[ "$RESP" != "n" ]]; do
    echo "Wrong input!"
    read -p "$1 (y/n)" RESP
  done

  echo "${RESP}"
}

function log_normal() {
  line="[$(date)] ${1}"
  echo -e "$line"
  if [[ -n "${CAMUNDA_CHALLENGE_LOG_FILE:-}" ]]; then
    echo "$line" >>"${CAMUNDA_CHALLENGE_LOG_FILE}"
  fi
}

function log_separator() {
  log_normal "--------------------------------------------------"
}

function log_test() {
  log_separator
  log_normal "${CYAN}[TEST]${NC} ${BOLD}${1}${NC}"
  log_separator
}

function log_info() {
  log_normal "${WHITE}[INFO]${NC} ${BOLD}${1}${NC}"
}

function log_error() {
  log_normal "${YELLOW}[ERROR]${NC} ${BOLD}${1}${NC}"
}

function log_warn() {
  log_normal "${YELLOW}[WARN]${NC} ${BOLD}${1}${NC}"
}

function log_pass() {
  log_normal "${GREEN}[PASS]${NC} ${BOLD}${1}${NC}"
}

function log_fail() {
  log_normal "${RED}[FAIL]${NC} ${BOLD}${1}${NC}"
}

function wait_for_camunda_deployment() {
  log_info "Waiting for Camunda Engine to be ready"
  kubectl wait --for=condition=available --timeout=300s deployment/camunda-deployment

  timeout=300
  wait_time=10
  while [[ $(kubectl get pods -l app=camunda -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' | tr ' ' '\n' | sort -u | grep "True" ||: ) != "True" ]]; do
    echo "Waiting for Camunda Engine pods to be ready..."
    sleep $wait_time
    timeout=$((timeout - wait_time))
    if [[ $timeout -lt 0 ]]; then
      break
    fi
  done
}

function wait_for_postgresql() {
  log_info "Waiting for PostgreSQL to be ready"
  count=20
  while [[ $count -gt 0 ]] ; do
    echo "Waiting for pod to be ready"
    kubectl wait --for=condition=ready pod --timeout=300s -l statefulset.kubernetes.io/pod-name=postgresql-0 && break || echo "pod not created yet"
    count=$((count - 1))
    sleep 5
  done

  if [[ $count -eq 0 ]]; then
    log_fail "Couldn't wait for Postgres pod to be ready"
    exit 1
  fi
}

function wait_for_autoscaler() {
  log_info "Waiting for Camunda Deployment Autoscaler to be ready"
  kubectl rollout status deployment/camunda-autoscaler --timeout=120s
  kubectl wait --for=condition=available --timeout=60s deployment/camunda-autoscaler
}

function wait_for_process_starter() {
  log_info "Waiting for Process Starter to be ready"
  kubectl rollout status deployment/camunda-process-starter --timeout=120s
  kubectl wait --for=condition=available --timeout=120s deployment/camunda-process-starter
}

function switch_k8s_context() {
  TARGET_CONTEXT="kind-$CLUSTER_NAME"
  CURRENT_CONTEXT=$(kubectl config current-context)

  if [[ "$TARGET_CONTEXT" != "$CURRENT_CONTEXT" ]]; then
    log_info "Switching to the context of the kind cluster ($TARGET_CONTEXT)"
    kubectl config use-context "$TARGET_CONTEXT"
  fi

  kubectl config set-context --current --namespace=default
}

function get_replica_count() {
  kubectl get "$1" -o=jsonpath='{.status.replicas}'
}

function get_camunda_replica_count() {
  get_replica_count deployment/camunda-deployment
}

function restart_rollout() {
  kubectl rollout restart "deployment/${1}" || log_warn "Could not restart rollout of deployment/${1}"
}

function adjust_process_starter() {
  log_info "Adjusting Process Starter rate to ${1} processes created per period"
  kubectl set env deployment/camunda-process-starter N_PROCESS_STARTED="${1}"
}

function apply_manifests() {
  SCRIPT=$(realpath "${0}")
  SCRIPTPATH=$(dirname "${SCRIPT}")
  RESOURCES_DIR="${SCRIPTPATH}/../k8s-resources"
  log_info "${2}"
  kubectl apply -f "${RESOURCES_DIR}/${1}"
  sleep 2
}

function wait_for_camunda_replica_count() {
  EXPECTED_COUNT=$1
  TIMEOUT=$2
  SLEEP_TIME=5
  STARTED=$(date -u +%s)
  TIMEOUT_PASSED=$((STARTED + TIMEOUT))

  while true; do
    COUNT=$(get_camunda_replica_count)
    TIMESTAMP=$(date -u +%s)
    log_info "Expecting Camunda Engine replicas: ${EXPECTED_COUNT}, current replicas: ${COUNT}"

    if [[ "$COUNT" == "$EXPECTED_COUNT" ]]; then
      log_info "Replica count matched!"
      return 0
    fi

    if [[ "$TIMESTAMP" -ge "$TIMEOUT_PASSED" ]]; then
      log_info "Timeout exceeded"
      break
    fi
    log_normal "Sleeping for ${SLEEP_TIME}s"
    sleep $SLEEP_TIME
  done

  log_info "Replica count did not match!"
  return 1
}
