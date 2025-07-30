# Signadot Operator

This chart installs Signadot Operator, which consists of the in-cluster
components for Signadot.


## Installing the Chart

To install this chart, the cluster should also be connected
in the [Signadot dashboard](https://app.signadot.com/settings/clusters) by
clicking "Connect Cluster".  This will provide you with a cluster token,
referred to below by `$CLUSTER_TOKEN`.


To install the chart with the release name `signadot-operator`:

```sh
# Create signadot namespace
kubectl create ns signadot

# Install
helm repo add signadot https://charts.signadot.com
helm install signadot-operator signadot/operator --set agent.clusterToken=$CLUSTER_TOKEN
```
The command deploys Signadot Operator on the Kubernetes cluster with default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.


## Cluster Tokens

If you installed the chart without a cluster token or would like to rotate the cluster
token, you can create the associated secret with

```sh
kubectl -n signadot create secret generic cluster-agent --from-literal=token=$CLUSTER_TOKEN
```

Note that to rotate the secret, you will need to delete the secret first and
also restart the agent deployment afterwards.

```sh
kubectl -n signadot delete secret cluster-agent
kubectl -n signadot create secret generic cluster-agent --from-literal=token=$CLUSTER_TOKEN
kubectl -n signadot rollout restart deploy agent
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


### Image and replicas customization parameters

The parameters in the table below allow one to specify image names for the
images used in our operator.  For each image, the image label `vX.Y.Z` refers to
the [operator version](https://www.signadot.com/docs/operator-version-policy).
Some images are sleighted for deprecation, in particular those with the suffix
`-legacy` in their name.

| Name                                  | Description                                              | Default                                |
| ------------------------------------- | -------------------------------------------------------- | -------------------------------------- |
| `controllerManager.replicas`          | Number of replicas for the Controller Manager deployment | `2`                                    |
| `controllerManager.image`             | Controller Manager image override                        | `signadot/controller-manager:vX.Y.Z`   |
| `controllerManager.imagePullPolicy`   | Controller Manager image pull policy                     | `IfNotPresent`                         |
| `agent.image`                         | Agent image override                                     | `signadot/agent:vX.Y.Z`                |
| `agent.imagePullPolicy`               | Agent image pull policy                                  | `IfNotPresent`                         |
| `routeServer.replicas`                | Number of replicas for the Route Server deployment       | `1`                                    |
| `routeServer.image`                   | Route Server image override                              | `signadot/route-server:vX.Y.Z`         |
| `routeServer.imagePullPolicy`         | Route Server image pull policy                           | `IfNotPresent`                         |
| `ioContextServer.replicas`            | Number of replicas for the IO Context Server deployment  | `1`                                    |
| `ioContextServer.image`               | IO Context Server image override                         | `signadot/io-context-server:vX.Y.Z`    |
| `ioContextServer.imagePullPolicy`     | IO Context Server image pull policy                      | `IfNotPresent`                         |
| `routeInit.image`                     | Route Init container image override                      | `signadot/route-sidecar-init:vX.Y.Z`   |
| `routeInit.legacy.image`              | Route Init container image override (legacy version)     | `signadot/sd-init-networking:latest`   |
| `routeInit.imagePullPolicy`           | Route Init container image pull policy                   | `IfNotPresent`                         |
| `routeInit.imagePullSecret`           | Route Init container image pull secret                   | `""`                                   |
| `routeSidecar.image`                  | Route Sidecar container image override                   | `signadot/route-sidecar:vX.Y.Z`        |
| `routeSidecar.legacy.image`           | Route Sidecar container image override (legacy version)  | `signadot/route-sidecar-legacy:vX.Y.Z` |
| `routeSidecar.imagePullPolicy`        | Route Sidecar container image pull policy                | `IfNotPresent`                         |
| `routeSidecar.imagePullSecret`        | Route Sidecar container image pull secret                | `""`                                   |
| `ioInit.image`                        | IO Init container image override                         | `signadot/io-init:vX.Y.Z`              |
| `ioInit.imagePullPolicy`              | IO Init container image pull policy                      | `IfNotPresent`                         |
| `ioInit.imagePullSecret`              | IO Init container image pull secret                      | `""`                                   |
| `ioSidecar.image`                     | IO Sidecar container image override                      | `signadot/io-sidecar:vX.Y.Z`           |
| `ioSidecar.imagePullPolicy`           | IO Sidecar container image pull policy                   | `IfNotPresent`                         |
| `ioSidecar.imagePullSecret`           | IO Sidecar container image pull secret                   | `""`                                   |
| `tunnel.api.replicas`                 | Number of replicas for the Tunnel API deployment         | `1`                                    |
| `tunnel.api.image`                    | Tunnel API image override                                | `signadot/tunnel-api:vX.Y.Z`           |
| `tunnel.api.imagePullPolicy`          | Tunnel API image pull policy                             | `IfNotPresent`                         |
| `tunnel.proxy.replicas`               | Number of replicas for the Tunnel Proxy deployment       | `1`                                    |
| `tunnel.proxy.image`                  | Tunnel Proxy image override                              | `signadot/tunnel-proxy:vX.Y.Z`         |
| `tunnel.proxy.imagePullPolicy`        | Tunnel Proxy image pull policy                           | `IfNotPresent`                         |
| `tunnel.auditor.image`                | Tunnel Auditor image override                            | `envoyproxy/envoy:v1.26.1`             |
| `tunnel.auditor.imagePullPolicy`      | Tunnel Auditor image pull policy                         | `IfNotPresent`                         |
| `tunnel.auditor.init.image`           | Tunnel Auditor Init image override                       | `signadot/tunnel-auditor-init:vX.Y.Z`  |
| `tunnel.auditor.init.imagePullPolicy` | Tunnel Auditor Init image pull policy                    | `IfNotPresent`                         |
| `trafficManager.replicas`             | Number of replicas for the Traffic Manager deployment    | `2`                                    |
| `trafficManager.image`                | Traffic Manager image override                           | `signadot/traffic-manager:vX.Y.Z`      |
| `trafficManager.imagePullPolicy`      | Traffic Manager image pull policy                        | `IfNotPresent`                         |
| `jobExecutorInit.image`               | Job Executor Init container image override               | `signadot/job-executor-init:vX.Y.Z`    |
| `jobExecutorInit.imagePullPolicy`     | Job Executor Init container image pull policy            | `IfNotPresent`                         |
| `jobExecutorInit.imagePullSecret`     | Job Executor Init container image pull secret            | `""`                                   |
| `jobExecutorProxy.image`              | Job Executor Proxy container image override              | `signadot/job-executor-proxy:vX.Y.Z`   |
| `jobExecutorProxy.imagePullPolicy`    | Job Executor Proxy container image pull policy           | `IfNotPresent`                         |
| `jobExecutorProxy.imagePullSecret`    | Job Executor Proxy container image pull secret           | `""`                                   |

ℹ️ For development clusters (such as Minikube, MicroK8s, or K3s), we recommend
running the controller manager with `controllerManager.replicas = 1` and the
traffic manager with `trafficManager.replicas = 1` to minimize resource usage.
Note that in the case of controller manager, increasing replicas (`replicas >
1`) does not replicate most controller functionality in parallel; only one
replica is active at a time, and high availability operates in an active-passive
manner, primarily benefiting sidecar injection.


### Resource customization parameters

<table>

<tr>
<th>
Name
</th>
<th>
Description
</th>
<th>
Default
</th>
</tr>

<tr>
<td>

`controllerManager.resources`

</td>
<td>
Controller Manager resources
</td>
<td>

```yaml
limits:
  cpu: 100m
  memory: 512Mi
requests:
  cpu: 100m
  memory: 512Mi
```

</td>
</tr>
<tr>
<td>

`agent.resources`

</td>
<td>
Agent resources
</td>
<td>

```yaml
limits:
  memory: 2Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`ioContextServer.resources`

</td>
<td>
IO Context Server resources
</td>
<td>

```yaml
limits:
  memory: 2Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`routeserver.resources`

</td>
<td>
Route Server resources
</td>
<td>

```yaml
limits:
  memory: 2Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`tunnel.api.resources`

</td>
<td>
Tunnel API resources
</td>
<td>

```yaml
limits:
  memory: 1Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`tunnel.proxy.resources`

</td>
<td>
Tunnel Proxy resources
</td>
<td>

```yaml
limits:
  memory: 2Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`tunnel.auditor.init.resources`

</td>
<td>
Tunnel Auditor Init container resources
</td>
<td>

```yaml
limits:
  memory: 2Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`tunnel.auditor.resources`

</td>
<td>
Tunnel Auditor resources
</td>
<td>

```yaml
limits:
  memory: 2Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`trafficManager.resources`

</td>
<td>
Traffic Manager resources
</td>
<td>

```yaml
limits:
  memory: 2Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`routeInit.resources`

</td>
<td>
Route Init container resources
</td>
<td>

```yaml
limits:
  cpu: "2"
  memory: 1Gi
requests:
  cpu: 100m
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`routeSidecar.resources`

</td>
<td>
Route Sidecar resources
</td>
<td>

```yaml
limits:
  cpu: "2"
  memory: 1Gi
requests:
  cpu: 100m
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`ioInit.resources`

</td>
<td>
IO Init container resources
</td>
<td>

```yaml
limits:
  cpu: "2"
  memory: 1Gi
requests:
  cpu: 100m
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`ioSidecar.resources`

</td>
<td>
IO Sidecar resources
</td>
<td>

```yaml
limits:
  cpu: "2"
  memory: 1Gi
requests:
  cpu: 100m
  memory: 128Mi
```

</td>
</tr>
</tr>
<tr>
<td>

`jobExecutorInit.resources`

</td>
<td>
Job Executor Init container resources
</td>
<td>

```yaml
limits:
  cpu: "2"
  memory: 1Gi
requests:
  cpu: 100m
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`jobExecutorProxy.resources`

</td>
<td>
Job Executor Proxy resources
</td>
<td>

```yaml
limits:
  cpu: "2"
  memory: 1Gi
requests:
  cpu: 100m
  memory: 128Mi
```

</td>
</tr>
</table>


### Controller Manager parameters

| Name                     | Description                                                                                               | Default |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | ------- |
| `allowedNamespaces`      | Restrict the namespaces in which `signadot-controller-manager` will operate                               | `[]`    |
| `allowOrphanedResources` | Allow Signadot Custom Resources to exist in the cluster when not created or managed via the control plane | `false` |


### Tunnel parameters

| Name                                     | Description                                                                                                                                                                                                                                                                  | Default |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `tunnel.api.strategy`                    | Strategy to be used for the Tunnel API deployment                                                                                                                                                                                                                            | `{}`    |
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
| `istio.operator.podLabels`      | Pod Labels to add to signadot components which should use Istio | `{"sidecar.istio.io/inject": "true"}`  |
| `istio.additionalAnnotations`       | Annotations to add to istio VirtualServices if not present                                                | `{}`    |
| `istio.additionalLabels`            | Labels to add to istio VirtualServices if not present                                                     | `{}`    |
| `istio.enableDeprecatedHostRouting` | Enable sandbox routing by matching the `VirtualService.host` field. **This feature has been deprecated**. | `false` |


### Linkerd parameters

Enabling Linkerd will activate the Linkerd proxy in the following components: in Signadot `agent` (for control-plane access to the cluster), in `tunnel-proxy` (to allow workstation access to the cluster via `signadot local connect`), and in the managed job runner group (for executing in-cluster smart tests).

Note that, unlike with Istio, routing in Linkerd is not expressed via Linkerd CRDs, but by using the DevMesh sidecars in the relevant workloads.

| Name              | Description              | Default |
| ----------------- | ------------------------ | ------- |
| `linkerd.enabled` | Enable Linkerd integration | `false` |
| `linkerd.operator.podAnnotations`      | Pod Annotations to add to signadot components which should use Linkerd |`{"linkerd.io/inject": "enabled"}`  |


### Routing parameters

| Name                    | Description                                                                           | Default  |
| ----------------------- | ------------------------------------------------------------------------------------- | -------- |
| `routing.iptablesMode`  | `iptables` variant to use when configuring rules (possible values: `legacy` or `nft`) | `legacy` |
| `routing.customHeaders` | List of custom headers used for sandbox routing                                       | `[]`     |



### Traffic capture parameters

| Name                                  | Description                                                 | Default |
| ------------------------------------- | ----------------------------------------------------------- | ------- |
| `trafficCapture.enabled`              | Enable traffic capture                                      | `true`  |
| `trafficCapture.requestHeadersElide`  | List of request headers to be elided from traffic captures  | `[]`    |
| `trafficCapture.responseHeadersElide` | List of response headers to be elided from traffic captures | `[]`    |

### Control plane parameters

| Name                                  | Description                                                 | Default |
| ------------------------------------- | ----------------------------------------------------------- | ------- |
| `controlPlane.proxy`              | Enable [control plane proxy](https://www.signadot.com/docs/concepts/architecture/control-plane#proxy-server)                                      | `enabled`  |
