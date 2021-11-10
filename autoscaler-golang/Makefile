# WARNING: You don't need to edit this file

APP_NAME=camunda-autoscaler
VERSION=1.0.0
LOCAL_REGISTRY=local.registry

LINTER=registry.camunda.cloud/library/cytopia/golint@sha256:0aa612729cd28e58551713772d6cf8337b4a1bc500cd37118c1fc0ab057cdb67
FORMATTER=registry.camunda.cloud/library/cytopia/gofmt@sha256:4841f8441239afcb23202626a572b43f24e1420ec9d96901f84f7b81d4e6f5aa
DOCKERFILE_LINTER=registry.camunda.cloud/library/hadolint/hadolint@sha256:c0aadd8ed276d99bd2d93661d8690f721b51c903600d58c73c00716879cfb718

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

build:  ## Builds docker image (for kind cluster)
	docker build -t $(LOCAL_REGISTRY)/$(APP_NAME):$(VERSION) .

# PUSH

push:  ## Pushes (loads) docker image to the Kind local cluster
	kind load docker-image $(LOCAL_REGISTRY)/$(APP_NAME):$(VERSION) --name $(CLUSTER)

# MISC

dockerfile-lint:  ## Runs Dockerfile linter
	docker run --rm -i $(DOCKERFILE_LINTER) < Dockerfile

lint:  ## Runs linter
	docker run --rm -v `pwd`:/data \
	  $(LINTER) -set_exit_status src/

fmt:  ## Runs formatter
	docker run --rm -v `pwd`:/data \
	  $(FORMATTER) src/ -w
