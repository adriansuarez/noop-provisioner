#!/bin/sh

set -e

# Create K8s cluster with four worker nodes
export KWOK_WORKDIR=/tmp
kwokctl create cluster --kubeconfig /tmp/kubeconfig.yaml
kwokctl scale node --replicas 4

# Configure kubectl to use K8s cluster
export KUBECONFIG=/tmp/kubeconfig.yaml

# Start noop volume provisioner that immediately binds PVCs
docker run -d --name noop-provisioner \
    -v /tmp/clusters/kwok/kubeconfig:/kubeconfig \
    -v /tmp/clusters/kwok/pki:/etc/kubernetes/pki \
    --network kwok-kwok \
    ghcr.io/adriansuarez/noop-provisioner:latest -kubeconfig /kubeconfig

# Create storage class for noop provisioner
kubectl apply -f https://raw.githubusercontent.com/adriansuarez/noop-provisioner/main/examples/storageclass.yaml

# Install CRDs for DBaaS
helm install nuodb-cp-crd nuodb-cp/nuodb-cp-crd

# Create basic service tier
kubectl apply -f - <<EOF
apiVersion: cp.nuodb.com/v1beta1
kind: ServiceTier
metadata:
  name: n0.nano
spec:
  features: []
EOF

# Create service account needed for AP
kubectl create serviceaccount nuodb

# Start DBaaS Operator
docker run -d --name nuodb-cp-operator \
    -v /tmp/clusters/kwok/kubeconfig:/home/nuodb/.kube/config \
    -v /tmp/clusters/kwok/pki:/etc/kubernetes/pki \
    -e ENABLE_WEBHOOKS=false \
    --network kwok-kwok \
    ghcr.io/nuodb/nuodb-cp-images:2.4.1 \
    controller --feature-gates EmbeddedDatabaseBackupPlugin=false

# Start DBaaS REST service
docker run -d --name nuodb-cp-rest -p 8080:8080 \
    -v /tmp/clusters/kwok/kubeconfig:/home/nuodb/.kube/config \
    -v /tmp/clusters/kwok/pki:/etc/kubernetes/pki \
    --network kwok-kwok \
    ghcr.io/nuodb/nuodb-cp-images:2.4.1 \
    nuodb-cp server start

# Create DBaaS system/admin user
docker exec nuodb-cp-rest nuodb-cp user create system/admin --allow 'all:*' --user-password changeIt --allow-cross-organization
