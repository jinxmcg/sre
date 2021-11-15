# Camunda Engine Kubernetes Autoscaler

Kubernetes autoscaler based on reported started processes:

- allows the deployment to be scaled up or down depending on number of processes
- easy configurable 

## Prerequisites

- Kubernetes service account with rights to be able to patch the number of replicas in the desired namespace and deployment

## Configuration
- **CAMUNDA_URL**: the external URL which reports the number of started processes in the interval
- **DELTA**: number of seconds between checks for scaling actions (default value: 10)
- **K8S_DEPLOYMENT**: name of the deployment to autoscale (default value: camunda-deployment)
- **K8S_NAMESPACE**: Kubernetes deployment namespace (default value: default)

## Example deployment

- Includes Kubernetes manifest case study for the Camunda Engine components deployment. It can be found in example/autoscaler.yml file

## File structire

- **main.py**:
Python implementation of the autoscaling mechanism
- **example/autoscaler.yml**:
Kubernetes case study for the Camunda Engine components deployment in example/autoscaler.yml file