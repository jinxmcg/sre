# SRE Coding Challenge (Camunda Engine Kubernetes Autoscaler)

This challenge includes a test framework, that:

- allows the candidates to less time on setting up the environment for the autoscaler
- allows both the candidates and the evaluators to check if the submitted solutions works as expected

# File Structure

## settings.sh

A candidate needs to place the language of their choice and well as their name, for the test
framework to work.

## Makefile

The main entrypoint to invoke different commands from the test framework:

- **make build**: Builds the autoscaler app and pushes the docker image to local kind registry
- **make check**: Checks all required tools are installed
- **make create**: Creates local kind cluster
- **make deploy**: Deploys autoscaler
- **make full-test**: Runs the full testing suite
- **make help**: This help
- **make lint**: Runs linters, check missing TODOs
- **make prepare**: Installs PostgreSQL, Camunda Engine, Process Starter in the local kind cluster
- **make scale**: Changes Process Starter's Process Creation rate (usage: make scale N=...)
- **make teardown**: Destroys local kind cluster and registry
- **make test**: Runs basic tests to check that autoscaler works

A candidate does not need to touch this file.

## Questions.md

A list of questions for the candidate to answer.

## autoscaler-*

These are the directories where a candidate needs to place the code for their autoscaler app 
(based on the language of their choice.)

## k8s-resources

Includes Kubernetes manifests for the Camunda Engine, PostgreSQL and Process Starter components.

A candidate needs to place the manifests for deploying their autoscaler app in the `autoscaler.yml` file.

## Scripts

Auxilliary scripts using by the `make` targets.

A candidate does not need to touch those.
A candidate normally does not need to run these directly.

- **_library.sh**: Library of the most-used reusable functions of the test framework
- **build-push-autoscaler.sh**: Builds autoscaler's docker image and pushes it to the registry of the test cluster
- **check-installed-tools.sh**: Checks that the required utilities for the challenge are installed (e.g. Docker)
- **check-todos.sh**: Checks that the TODOs are fixed by the candidate
- **codestyle.sh**: Runs a linter for the autoscaler code
- **create-kind-cluster.sh**: Creates a test kind cluster with the name from `settings.sh`
- **delete-kind-cluster.sh**: Deletes a test kind cluster and its registry
- **deploy-autoscaler.sh**: Deploys autoscaler app in the test cluster
- **deploy-camunda.sh**: Deploys Camunda Engine in the test cluster
- **deploy-postgresql.sh**: Deploys PostgreSQL in the test cluster
- **deploy-process-starter.sh**: Deploys Process Starter in the test cluster
- **parselog.sh**: Parses test log and outputs various stats on it
- **test-autoscaler.sh**: Tests the autoscaler's behaviour for different process creation rates.
