#!/bin/bash

# Submit del workflow Argo
echo "Submitting Argo workflow..."
argo submit k8s-gke/argoWorkflow/job-test-cloud.yaml -n argo --watch

# Deploy dei servizi API e UI
echo "Applying Kubernetes deployments and services..."
kubectl apply -f k8s-gke/deployment/
