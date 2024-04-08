# noop-provisioner

This is a trivial volume provisioner that is intended to be used to simulate scheduling of stateful workloads, to enable testing with tools like [KWOK](https://github.com/kubernetes-sigs/kwok).
This is based on [hostpath-provisioner](https://github.com/kubernetes-sigs/sig-storage-lib-external-provisioner/tree/master/examples/hostpath-provisioner) example of the external-provisioner controller.

Example usage in `kwok` cluster:

```bash
# Create K8s cluster and add worker nodes
export KWOK_WORKDIR=/tmp
export KUBECONFIG=/tmp/kubeconfig.yaml
kwokctl create cluster --wait 1m
kwokctl scale node --replicas 4

# Start noop volume provisioner that immediately binds PVCs
docker run -d --name noop-provisioner \
    -v /tmp/clusters/kwok/kubeconfig:/kubeconfig \
    -v /tmp/clusters/kwok/pki:/etc/kubernetes/pki \
    --network kwok-kwok \
    ghcr.io/adriansuarez/noop-provisioner:latest -kubeconfig /kubeconfig

# Create storage class for noop provisioner
kubectl apply -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: noop
provisioner: nuodb.github.io/noop-provisioner
EOF

# Create stateful workloads (NuoDB domain and database)
helm install nuodb-admin --repo https://nuodb.github.io/nuodb-helm-charts admin
helm install nuodb-database --repo https://nuodb.github.io/nuodb-helm-charts database
```
