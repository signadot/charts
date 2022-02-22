# Signadot Operator

This chart installs Signadot Operator, which consists of the in-cluster
components for Signadot.

## Installation

```sh
# Create signadot namespace
kubectl create ns signadot

# Install
helm repo add signadot https://charts.signadot.com
helm install signadot-operator signadot/operator

# Upgrade
helm repo update
helm upgrade signadot-operator signadot/operator

# Uninstall
helm uninstall signadot-operator

# Remove signadot namespace
kubectl delete ns signadot
```

## Cluster Registration

In addition to installing this chart, the cluster must also be registered
in the [Signadot dashboard](https://app.signadot.com).

After generating a cluster token, complete the registration by populating a Secret
called `cluster-agent` in the `signadot` namespace:

```sh
# Replace "..." with the token value.
kubectl -n signadot create secret generic cluster-agent --from-literal=token=...
```
