#!/bin/bash

# WARNING: You don't need to edit this file!

# This script checks that the following tools are installed:
# - Docker
# - kind
# - kubectl

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -eu

SUCCESS="true"

function mark_fail() {
  SUCCESS="false"
}

function check_command() {
  CMD="$1"
  log_test "Checking that $CMD is installed"
  if ! "$CMD" &> /dev/null
  then
    log_fail "$CMD not installed or not running"
    return 1
  else
    log_pass "$CMD is installed"
  fi
}


check_command docker && log_info "$(docker --version)" || mark_fail

docker_running=$(docker info >/dev/null 2>&1 && echo "true" || echo "false")
if [[ $docker_running == "true" ]]; then
  log_info "Docker daemon is runnning"
else
  log_fail "Docker daemon is not running"
  mark_fail
fi

check_command kubectl && log_info "$(kubectl version --client=true)" || mark_fail

check_command kind && log_info "$(kind --version)" || mark_fail

[[ $SUCCESS != "true" ]] && exit 1 || exit 0
