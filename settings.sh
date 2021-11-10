#!/bin/bash

CLUSTER_NAME=cristian.malaia # TODO please put your name here. It will be used for the name of kind cluster (format: fistname.lastname, only [a-z\.] characters allowed)
AUTOSCALER_LANGUAGE=python  # TODO please put the language you chose to use here (possible options: python, golang)

[ -z "$AUTOSCALER_LANGUAGE" ] && echo "Programming language for autoscaler not defined, please fill it in settings.sh" && exit 1

[ -z "$CLUSTER_NAME" ] && echo "Cluster name is not defined, please fill it in settings.sh" && exit 1
