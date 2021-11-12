#!/bin/bash

# WARNING: You don't need to edit this file!

# Deletes a kind cluster and its registry

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

. "${SCRIPTPATH}/../settings.sh"
. "${SCRIPTPATH}/_library.sh"

parse_log() {
  FILE="$1"

  if [[ -n $FILE ]]; then
    COUNT_TEST=$(cat "$FILE" | grep "\[TEST\]" | wc -l)
    COUNT_FAIL=$(cat "$FILE" | grep "\[FAIL\]" | wc -l)
    COUNT_PASS=$(cat "$FILE" | grep "\[PASS\]" | wc -l)
    COUNT_WARN=$(cat "$FILE" | grep "\[WARN\]" | wc -l)

    echo -e "\n${CYAN}Tests: ${COUNT_TEST}${NC}, ${GREEN}Passed: ${COUNT_PASS}${NC}, ${RED}Failed: ${COUNT_FAIL}${NC}, ${YELLOW}Warnings: ${COUNT_WARN}${NC}"

    TESTS_WARN=$(cat "$FILE" | grep -e "\[TEST\]" -e "\[WARN\]" | grep -e "\[WARN\]" -B 1 | grep -v -- "^--$")
    TESTS_FAIL=$(cat "$FILE" | grep -e "\[TEST\]" -e "\[FAIL\]" | grep -e "\[FAIL\]" -B 1 | grep -v -- "^--$")

    if [[ $(( COUNT_FAIL + COUNT_WARN)) -gt 0 ]]; then
      echo -e "\nSummary of FAIL and WARN tests"
    fi

    if [[ ${COUNT_FAIL} -gt 0 ]] ; then
      echo -e "\n${TESTS_FAIL}"
    fi

    if [[ ${COUNT_WARN} -gt 0 ]] ; then
      echo -e "\n${TESTS_WARN}"
    fi
  else
    echo "No log file to parse found"
  fi
}

parse_log "$CAMUNDA_CHALLENGE_LOG_FILE"