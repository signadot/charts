# Signadot Workspaces

This chart installs the in-cluster components for Signadot Workspaces.

## Prerequisites

Please [install cert-manager](https://cert-manager.io/docs/installation/kubernetes/)
first if it's not already installed in the cluster.
This chart relies on cert-manager to generate the certificate for its admission webhook.

## Installation

```sh
# Install
helm repo add signadot https://charts.signadot.com
helm install signadot-workspaces signadot/workspaces

# Upgrade
helm repo update
helm upgrade signadot-workspaces signadot/workspaces

# Uninstall
helm uninstall signadot-workspaces
```

## Cluster Registration

In addition to installing this chart, the cluster must also be registered
in the [Signadot Workspaces console](https://app.signadot.com).

After generating a cluster token, complete the registration by populating a Secret
called `cluster-agent` in the `signadot` namespace:

```sh
# Replace "..." with the token value.
kubectl -n signadot create secret generic cluster-agent --from-literal=token=...
```
