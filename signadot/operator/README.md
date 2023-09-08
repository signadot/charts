# Signadot Operator

This chart installs Signadot Operator, which consists of the in-cluster
components for Signadot.

## Installing the Chart

To install the chart with the release name `signadot-operator`:

```sh
# Create signadot namespace
kubectl create ns signadot

# Install
helm repo add signadot https://charts.signadot.com
helm install signadot-operator signadot/operator
```
The command deploys Signadot Operator on the Kubernetes cluster with default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.


## Cluster Registration

In addition to installing this chart, the cluster must also be registered
in the [Signadot dashboard](https://app.signadot.com).

After generating a cluster token, complete the registration by populating a Secret
called `cluster-agent` in the `signadot` namespace:

```sh
# Replace "..." with the token value.
kubectl -n signadot create secret generic cluster-agent --from-literal=token=...
```

## Upgrading the Chart

To upgrade an existing `signadot-operator` deployment:

```sh
# Upgrade
helm repo update
helm upgrade signadot-operator signadot/operator
```

## Uninstalling the Chart

To uninstall/delete the `signadot-operator` deployment:

```sh
# Uninstall
helm uninstall signadot-operator

# Remove signadot namespace
kubectl delete ns signadot
```

## Parameters

### Common parameters

| Name                 | Description                                               | Default  |
| -------------------- | --------------------------------------------------------- | -------- |
| `commonLabels`       | Labels to add to all deployed objects                     | `{}`     |
| `commonAnnotations`  | Annotations to add to all deployed objects                | `{}`     |
| `podLabels`          | Labels to add to all deployed `Pod` objects               | `{}`     |
| `podAnnotations`     | Annotations to add to all deployed `Pod` objects          | `{}`     |
| `serviceLabels`      | Labels to add to all deployed `Service` objects           | `{}`     |
| `serviceAnnotations` | Annotations to add to all deployed `Service` objects      | `{}`     |

### Image customization parameters

| Name                                  | Description                                             | Default        |
| ------------------------------------- | ------------------------------------------------------- | -------------- |
| `operator.image`                      | Operator image override                                 | `""`           |
| `operator.imagePullPolicy`            | Operator image pull policy                              | `IfNotPresent` |
| `agent.image`                         | Agent image override                                    | `""`           |
| `agent.imagePullPolicy`               | Agent image pull policy                                 | `IfNotPresent` |
| `routeServer.image`                   | Route Server image override                             | `""`           |
| `routeServer.imagePullPolicy`         | Route Server image pull policy                          | `IfNotPresent` |
| `ioContextServer.image`               | IO Context Server image override                        | `""`           |
| `ioContextServer.imagePullPolicy`     | IO Context Server image pull policy                     | `IfNotPresent` |
| `kubeRBACProxy.image`                 | Kube-rbac-proxy image override                          | `""`           |
| `kubeRBACProxy.imagePullPolicy`       | Kube-rbac-proxy image pull policy                       | `IfNotPresent` |
| `routeInit.image`                     | Route Init container image override                     | `""`           |
| `routeInit.legacy.image`              | Route Init container image override (legacy version)    |                |
| `routeInit.imagePullPolicy`           | Route Init container image pull policy                  | `IfNotPresent` |
| `routeInit.imagePullSecret`           | Route Init container image pull secret                  | `""`           |
| `routeSidecar.image`                  | Route Sidecar container image override                  | `""`           |
| `routeSidecar.legacy.image`           | Route Sidecar container image override (legacy version) | `""`           |
| `routeSidecar.imagePullPolicy`        | Route Sidecar container image pull policy               | `IfNotPresent` |
| `routeSidecar.imagePullSecret`        | Route Sidecar container image pull secret               | `""`           |
| `ioInit.image`                        | IO Init container image override                        | `""`           |
| `ioInit.imagePullPolicy`              | IO Init container image pull policy                     | `IfNotPresent` |
| `ioInit.imagePullSecret`              | IO Init container image pull secret                     | `""`           |
| `ioSidecar.image`                     | IO Sidecar container image override                     | `""`           |
| `ioSidecar.imagePullPolicy`           | IO Sidecar container image pull policy                  | `IfNotPresent` |
| `ioSidecar.imagePullSecret`           | IO Sidecar container image pull secret                  | `""`           |
| `execpodSidecar.image`                | ExecPod Sidecar container image override                | `""`           |
| `execpodSidecar.imagePullPolicy`      | ExecPod Sidecar container image pull policy             | `IfNotPresent` |
| `execpodSidecar.imagePullSecret`      | ExecPod Sidecar container image pull secret             | `""`           |
| `tunnel.api.image`                    | Tunnel API image override                               | `""`           |
| `tunnel.api.imagePullPolicy`          | Tunnel API image pull policy                            | `IfNotPresent` |
| `tunnel.proxy.image`                  | Tunnel Proxy image override                             | `""`           |
| `tunnel.proxy.imagePullPolicy`        | Tunnel Proxy image pull policy                          | `IfNotPresent` |
| `tunnel.auditor.init.image`           | Tunnel Auditor init image override                      | `""`           |
| `tunnel.auditor.init.imagePullPolicy` | Tunnel Auditor init image pull policy                   | `IfNotPresent` |

### Tunnel parameters

| Name                                     | Description                                                                                                                                                                                                                                                                  | Default |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `tunnel.api.replicas`                    | Number of replicas for the Tunnel API deployment                                                                                                                                                                                                                             | `1`     |
| `tunnel.api.resources`                   | Resources for the Tunnel API deployment                                                                                                                                                                                                                                      | `{}`    |
| `tunnel.api.strategy`                    | Strategy to be used for the Tunnel API deployment                                                                                                                                                                                                                            | `{}`    |
| `tunnel.proxy.replicas`                  | Number of replicas for the Tunnel Proxy deployment                                                                                                                                                                                                                           | `1`     |
| `tunnel.proxy.resources`                 | Resources for the Tunnel Proxy deployment                                                                                                                                                                                                                                    | `{}`    |
| `tunnel.proxy.strategy`                  | Strategy to be used for the Tunnel Proxy deployment                                                                                                                                                                                                                          | `{}`    |
| `tunnel.config.cidrs`                    | Default CIDRs configuration to be used for connected clients                                                                                                                                                                                                                 | `""`    |
| `tunnel.config.externalDNS.server`       | If configured, the Tunnel API will pull this server to fetch domains which will be added to the `/etc/hosts` of the connected clients                                                                                                                                        | `""`    |
| `tunnel.config.externalDNS.syncInterval` | Time interval, in seconds, for pulling the configured `externalDNS.server`                                                                                                                                                                                                   | `30`    |
| `tunnel.config.disableSSH`               | Disable the SSH reverse tunnel endpoint in Tunnel Proxy                                                                                                                                                                                                                      | `false` |
| `tunnel.config.disableXAP`               | Disable the XAP reverse tunnel endpoint in Tunnel Proxy                                                                                                                                                                                                                      | `false` |
| `tunnel.auditor.luaRocks`                | This is an optional, space-separated list of Lua packages (called rocks) to install in the Envoy auditor Lua environment.                                                                                                                                                    | `""`    |
| `tunnel.auditor.inboundRulesLuaScript`   | All inbound traffic (from cluster to workstation) will pass thru this script (if defined) in the Envoy auditor, check [HTTP Lua filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter#stream-handle-api) documentation for details  | `""`    |
| `tunnel.auditor.outboundRulesLuaScript`  | All outbound traffic (from workstation to cluster) will pass thru this script (if defined) in the Envoy auditor, check [HTTP Lua filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter#stream-handle-api) documentation for details | `""`    |
|                                          |                                                                                                                                                                                                                                                                              |         |