#!/bin/bash

# WARNING: You don't need to edit this file!

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

set -e

ROOT_DIR="${SCRIPTPATH}/../"
AUTOSCALER_DIR="${SCRIPTPATH}/../autoscaler-${AUTOSCALER_LANGUAGE}"

function check_todos_missing_in_file() {
  FILENAME="$1"
  LINE="TODO:"
  grep -q "$LINE" "$FILENAME" && c=0 || c=1
  [[ $c == 0 ]] && log_fail "Found TODOs in ${FILENAME}" || log_pass "No TODOs found in ${FILENAME}"
}

log_test "Check that todos are addressed in Questions.md"
check_todos_missing_in_file "${ROOT_DIR}/Questions.md"

log_test "Check that todos are addressed in autoscaler.yml"
check_todos_missing_in_file "${ROOT_DIR}/k8s-resources/autoscaler.yml"

log_test "Check that todos are addressed in Dockerfile"
check_todos_missing_in_file "${AUTOSCALER_DIR}/Dockerfile"

log_test "Check that todos are addressed in README.md"
check_todos_missing_in_file "${AUTOSCALER_DIR}/README.md"

if [[ "${AUTOSCALER_LANGUAGE}" == "python" ]]; then
  log_test "Check that todos are addressed in requirements.txt"
  check_todos_missing_in_file "${AUTOSCALER_DIR}/requirements.txt"

  log_test "Check that todos are addressed in main.py"
  check_todos_missing_in_file "${AUTOSCALER_DIR}/main.py"
fi

if [[ "${AUTOSCALER_LANGUAGE}" == "golang" ]]; then
  log_test "Check that todos are addressed in main.go"
  check_todos_missing_in_file "${AUTOSCALER_DIR}/src/main.go"
fi
