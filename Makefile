# WARNING: You don't need to edit this file

SH := /bin/bash

.EXPORT_ALL_VARIABLES:
CAMUNDA_CHALLENGE_LOG_FILE := $(if $(CAMUNDA_CHALLENGE_LOG_FILE),$(CAMUNDA_CHALLENGE_LOG_FILE),$(shell mktemp))
N?=0   # default process creation rate

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

.DEFAULT_GOAL := help

bootstrap: create prepare

start-log:
	@echo "Saving logfile to: $(CAMUNDA_CHALLENGE_LOG_FILE)"

end-log:
	./scripts/parselog.sh

create:  ## Creates local kind cluster
	./scripts/create-kind-cluster.sh

check: ## Checks all required tools are installed
	./scripts/check-installed-tools.sh

prepare:  ## Installs PostgreSQL, Camunda Engine, Process Starter in the local kind cluster
	./scripts/deploy-postgresql.sh
	./scripts/deploy-camunda.sh
	./scripts/deploy-process-starter.sh 0

build:  ## Builds the autoscaler app and pushes the docker image to local kind registry
	./scripts/build-push-autoscaler.sh

lint:  ## Runs linters, check missing TODOs
	./scripts/check-todos.sh
	./scripts/codestyle.sh

test:  ## Runs basic tests to check that autoscaler works
	./scripts/test-autoscaler.sh

deploy:  ## Deploys autoscaler
	./scripts/deploy-autoscaler.sh

scale:  ## Changes Process Starter's Process Creation rate (usage: make scale N=...)
	./scripts/deploy-process-starter.sh $(N)

teardown:  ## Destroys local kind cluster and registry
	./scripts/delete-kind-cluster.sh

full-test:  ## Runs the full testing suite
	$(MAKE) start-log
	$(MAKE) check || ( $(MAKE) end-log ; exit 1 )
	$(MAKE) bootstrap || ( $(MAKE) end-log ; exit 1 )
	$(MAKE) lint || ( $(MAKE) end-log ; )
	$(MAKE) build || ( $(MAKE) end-log ; exit 1 )
	$(MAKE) deploy || ( $(MAKE) end-log ; exit 1 )
	$(MAKE) test || ( $(MAKE) end-log ; exit 1 )
	$(MAKE) teardown || ( $(MAKE) end-log ; exit 1 )
	$(MAKE) end-log
