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

### Controller Manager parameters

| Name                            | Description                                                                 | Default |
| ------------------------------- | --------------------------------------------------------------------------- | ------- |
| `allowedNamespaces`             | Restrict the namespaces in which `signadot-controller-manager` will operate | `[]`    |
| `sandboxTrafficManager.enabled` | Whether to enable the sandbox traffic manager sidecar on forked workloads   | `true`  |


### Image customization parameters

The parameters in the table below allow one to specify image names for the
images used in our operator.  For each image, the image label `vX.Y.Z` refers
to the [operator
version](https://www.signadot.com/docs/operator-version-policy).  Some images
are sleighted for deprecation, in particular those with the suffix `-legacy` in
their name.  Additionally, the `execpod-` images are for compatibility with old
style resources and are not needed in an installation which uses the new
[resource plugins](https://www.signadot.com/docs/resourceplugins).

| Name                                  | Description                                             | Default                                |
| ------------------------------------- | ------------------------------------------------------- | -------------------------------------- |
| `operator.image`                      | Operator image override                                 | `signadot/operator:vX.Y.Z`             |
| `operator.imagePullPolicy`            | Operator image pull policy                              | `IfNotPresent`                         |
| `agent.image`                         | Agent image override                                    | `signadot/agent:vX.Y.Z`                |
| `agent.imagePullPolicy`               | Agent image pull policy                                 | `IfNotPresent`                         |
| `routeServer.image`                   | Route Server image override                             | `signadot/route-server:vX.Y.Z`         |
| `routeServer.imagePullPolicy`         | Route Server image pull policy                          | `IfNotPresent`                         |
| `ioContextServer.image`               | IO Context Server image override                        | `signadot/io-context-server:vX.Y.Z`    |
| `ioContextServer.imagePullPolicy`     | IO Context Server image pull policy                     | `IfNotPresent`                         |
| `kubeRBACProxy.image`                 | Kube-rbac-proxy image override                          | `""`                                   |
| `kubeRBACProxy.imagePullPolicy`       | Kube-rbac-proxy image pull policy                       | `IfNotPresent`                         |
| `routeInit.image`                     | Route Init container image override                     | `signadot/route-sidecar-init:vX.Y.Z`   |
| `routeInit.legacy.image`              | Route Init container image override (legacy version)    | `signadot/sd-init-networking:latest`   |
| `routeInit.imagePullPolicy`           | Route Init container image pull policy                  | `IfNotPresent`                         |
| `routeInit.imagePullSecret`           | Route Init container image pull secret                  | `""`                                   |
| `routeSidecar.image`                  | Route Sidecar container image override                  | `signadot/route-sidecar:vX.Y.Z`        |
| `routeSidecar.legacy.image`           | Route Sidecar container image override (legacy version) | `signadot/route-sidecar-legacy:vX.Y.Z` |
| `routeSidecar.imagePullPolicy`        | Route Sidecar container image pull policy               | `IfNotPresent`                         |
| `routeSidecar.imagePullSecret`        | Route Sidecar container image pull secret               | `""`                                   |
| `ioInit.image`                        | IO Init container image override                        | `signadot/io-init:vX.Y.Z`              |
| `ioInit.imagePullPolicy`              | IO Init container image pull policy                     | `IfNotPresent`                         |
| `ioInit.imagePullSecret`              | IO Init container image pull secret                     | `""`                                   |
| `ioSidecar.image`                     | IO Sidecar container image override                     | `signadot/io-sidecar:vX.Y.Z`           |
| `ioSidecar.imagePullPolicy`           | IO Sidecar container image pull policy                  | `IfNotPresent`                         |
| `ioSidecar.imagePullSecret`           | IO Sidecar container image pull secret                  | `""`                                   |
| `execpodSidecar.image`                | ExecPod Sidecar container image override                | `signadot/execpod-sidecar:vX.Y.Z`      |
| `execpodSidecar.imagePullPolicy`      | ExecPod Sidecar container image pull policy             | `IfNotPresent`                         |
| `execpodSidecar.imagePullSecret`      | ExecPod Sidecar container image pull secret             | `""`                                   |
| `tunnel.api.image`                    | Tunnel API image override                               | `signadot/tunnel-api:vX.Y.Z`           |
| `tunnel.api.imagePullPolicy`          | Tunnel API image pull policy                            | `IfNotPresent`                         |
| `tunnel.proxy.image`                  | Tunnel Proxy image override                             | `signadot/tunnel-proxy:vX.Y.Z`         |
| `tunnel.proxy.imagePullPolicy`        | Tunnel Proxy image pull policy                          | `IfNotPresent`                         |
| `tunnel.auditor.image`                | Tunnel Auditor image override                           | `envoyproxy/envoy:v1.26.1`             |
| `tunnel.auditor.imagePullPolicy`      | Tunnel Auditor image pull policy                        | `IfNotPresent`                         |
| `tunnel.auditor.init.image`           | Tunnel Auditor Init image override                      | `signadot/tunnel-auditor-init:vX.Y.Z`  |
| `tunnel.auditor.init.imagePullPolicy` | Tunnel Auditor Init image pull policy                   | `IfNotPresent`                         |
| `jobExecutorInit.image`               | Job Executor Init container image override              | `signadot/job-executor-init:vX.Y.Z`    |
| `jobExecutorInit.imagePullPolicy`     | Job Executor Init container image pull policy           | `IfNotPresent`                         |
| `jobExecutorInit.imagePullSecret`     | Job Executor Init container image pull secret           | `""`                                   |
| `jobExecutorProxy.image`              | Job Executor Proxy container image override             | `signadot/job-executor-proxy:vX.Y.Z`   |
| `jobExecutorProxy.imagePullPolicy`    | Job Executor Proxy container image pull policy          | `IfNotPresent`                         |
| `jobExecutorProxy.imagePullSecret`    | Job Executor Proxy container image pull secret          | `""`                                   |
| `sandboxTrafficManager.init.Image`     | Sandbox traffic manager sidecar image override | `signadot/sandbox-traffic-manager:vX.Y.Z`                         |
| `sandboxTrafficManager.init.ImagePullPolicy`     | Sandbox traffic manager sidecar image pull policy | `IfNotPresent`                         |
| `sandboxTrafficManager.init.ImagePullSecret`     | Sandbox traffic manager sidecar image pull secret | `""`                         |
| `sandboxTrafficManager.sidecar.Image`     | Sandbox traffic manager sidecar image override | `signadot/sandbox-traffic-manager:vX.Y.Z`                         |
| `sandboxTrafficManager.sidecar.ImagePullPolicy`     | Sandbox traffic manager sidecar image pull policy | `IfNotPresent`                         |
| `sandboxTrafficManager.sidecar.ImagePullSecret`     | Sandbox traffic manager sidecar image pull secret | `""`                         |


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
### Istio parameters

When Istio is enabled (`istio.enabled: true`), the Signadot Operator manipulates Istio VirtualServices by applying new HTTPRoutes where appropriate to direct traffic to sandboxed workloads. You can configure the operator to add labels and annotations to these objects when they are in use by the operator.  Note that these labels and annotations are only added when the object comes into use. This can be useful for temporarily disabling CI sync, amongst other possibilities.

Enabling Istio will activate the Istio proxy in the following components: in Signadot `agent` (for control-plane access to the cluster), in `tunnel-proxy` (to allow workstation access to the cluster via `signadot local connect`), and in the managed job runner group (for executing in-cluster smart tests).

| Name                                | Description                                                                                               | Default |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------- | ------- |
| `istio.enabled`                     | Enable Istio integration                                                                                  | `false` |
| `istio.additionalAnnotations`       | Annotations to add to istio VirtualServices if not present                                                | `{}`    |
| `istio.additionalLabels`            | Labels to add to istio VirtualServices if not present                                                     | `{}`    |
| `istio.enableDeprecatedHostRouting` | Enable sandbox routing by matching the `VirtualService.host` field. **This feature has been deprecated**. | `false` |


### Linkerd parameters

Enabling Linkerd will activate the Linkerd proxy in the following components: in Signadot `agent` (for control-plane access to the cluster), in `tunnel-proxy` (to allow workstation access to the cluster via `signadot local connect`), and in the managed job runner group (for executing in-cluster smart tests).

Note that, unlike with Istio, we don't have a native integration for Linkerd. Therefore, to enable sandbox routing, DevMesh must be enabled in the relevant workloads.

| Name              | Description              | Default |
| ----------------- | ------------------------ | ------- |
| `linkerd.enabled` | Enable Istio integration | `false` |


### Routing parameters

| Name                    | Description                                     | Default |
| ----------------------- | ----------------------------------------------- | ------- |
| `routing.customHeaders` | List of custom headers used for sandbox routing | `[]`    |


### Traffic capture parameters

| Name                                  | Description                                                 | Default |
| ------------------------------------- | ----------------------------------------------------------- | ------- |
| `trafficCapture.enabled`              | Enable traffic capture                                      | `true`  |
| `trafficCapture.requestHeadersElide`  | List of request headers to be elided from traffic captures  | `[]`    |
| `trafficCapture.responseHeadersElide` | List of response headers to be elided from traffic captures | `[]`    |