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
helm install signadot-operator signadot/operator --set controlPlane.clusterToken=$CLUSTER_TOKEN
```
The command deploys Signadot Operator on the Kubernetes cluster with default
configuration. The [Parameters](#parameters) section lists the parameters that
can be configured during installation.


## Cluster Tokens

If you installed the chart without a cluster token or would like to rotate the cluster
token, you can create the associated secret with

```sh
kubectl -n signadot create secret generic cluster-token --from-literal=token=$CLUSTER_TOKEN
```

To rotate the secret, update the existing secret with the new value. Running
services will automatically detect the change and begin using the updated
secret. E.g.:

```sh
kubectl -n signadot patch secret cluster-token \
  --type=merge -p '{"stringData":{"token":"'"$CLUSTER_TOKEN"'"}}'
```

If you have specified a custom secret name via the `controlPlane.tokenSecret`
value, then you should replace `cluster-token` above with the value of
`controlPlane.tokenSecret`.

## DevMesh Injection

DevMesh is Signadot's sidecar-based routing: a per-workload proxy that routes by
routing key without needing a service mesh. The chart installs a mutating
admission webhook, `sidecar-injector.signadot.com`, which runs on Pod creation
and injects the DevMesh sidecar (`sd-sidecar`) into workloads that ask for it. A
workload asks for it with the `sidecar.signadot.com/inject: "true"` annotation on
its Pod template, or with the same key as a label on its namespace to cover the
Pods created there.

Injection resolves only for Pods owned by a Deployment or an Argo Rollout. Pods
belonging to a StatefulSet, DaemonSet or Job, and Pods created directly, start
without the DevMesh sidecar and carry a `sidecar.signadot.com/processed`
annotation recording why. That applies to both ways of asking, so labelling a namespace
covers the Deployments and Rollouts in it rather than everything in it.

The webhook is consulted for Pod creation in all namespaces except `kube-system`
and `kube-node-lease`. Being consulted is not the same as being injected: Pods
that do not ask for injection are returned unchanged.

To keep the webhook out of a namespace entirely, so that no admission call is
made for Pods created there, label the namespace:

```sh
kubectl label namespace $NAMESPACE signadot.com/admission-webhooks=disabled
```

Remove the label to bring the namespace back into scope:

```sh
kubectl label namespace $NAMESPACE signadot.com/admission-webhooks-
```

This label governs only whether the API server calls the webhook. It is
independent of `allowedNamespaces`, which governs the namespaces Signadot
operates in.

### Not installing the webhook

`devMesh.enabled: false` disables DevMesh injection. Use it where routing is
handled another way — Istio, Gateway API (with Istio or Linkerd), or an external
component such as an API gateway. Linkerd on its own routes *through* the DevMesh
sidecar, so `linkerd.enabled` without `linkerd.gatewayAPI.enabled` is refused at
install time rather than left to fail at the first sandbox. It skips the `MutatingWebhookConfiguration`, the
`signadot-webhook-service` Service, and the `signadot-devmesh-injector`
ClusterRole (the operator's cluster-wide `namespaces` read and its CA bundle
write). The Kubernetes API server then makes no admission call when a Pod is
created anywhere in the cluster, and the operator stops serving the admission
endpoint at all — so nothing is injected even if a `MutatingWebhookConfiguration`
is present for some other reason. The `webhook-server-cert` Secret is still
created, because that keypair doubles as a client certificate.

Every baseline Service then needs its routing to come from somewhere else: a mesh
route, or the `routing.signadot.com/external` annotation declaring that an
external component owns it. A Service with neither leaves its sandbox not ready.

The `sidecar.signadot.com/inject` annotation has no effect once DevMesh is
disabled; remove it from workloads that no longer need it. Pods created on a
disabled cluster also carry no `sidecar.signadot.com/processed` annotation, since
nothing is consulted to write one, and pods already running with an injected
sidecar keep it until they are rolled.

## Upgrading the Chart

To upgrade an existing `signadot-operator` deployment:

```sh
# Upgrade
helm repo update
helm upgrade signadot-operator signadot/operator
```

### Behavior changes in this release

- The Route Server's legacy routes API on port 8080 no longer serves by
  default; every request to that port, `/healthz` included, answers `410 Gone`.
  Ports 7777 (gRPC) and 7778 (HTTP), which is what current route sidecars use,
  are unchanged, as is the `routeserver-metrics` Service on port 9090. If
  something in your cluster still reads routes from port 8080, set
  `routeServer.legacyRoutesAPI.enabled: true` to keep it working through this
  release; the legacy API is removed in the next one. A health check pointed at
  port 8080 should move to `/healthz` on port 7778, which serves the same
  response and is not going away.
- The preview server is new and installed by default: upgrading adds a
  `previewserver` Deployment, Service, ServiceAccount, ClusterRole and
  ClusterRoleBinding to the `signadot` namespace. It runs one replica (128Mi
  requested, 1Gi limit) and reads `routingconfigs` cluster-wide. Set
  `previewServer.enabled: false` to install none of it; the same value is what
  tells the control plane not to serve previews for this cluster.
- The DevMesh injection webhook no longer rejects a Pod when the operator
  itself fails. Four internal failure paths previously returned an admission
  response with `allowed: false`, which the API server honors regardless of
  `failurePolicy: Ignore`, so a fault on our side could block Pod creation
  across the cluster. They now allow the Pod through, as does a panic escaping
  the handler: it starts without the DevMesh sidecar and carries a
  `sidecar.signadot.com/processed` annotation recording why. The failure mode
  moves from "the Pod does not start" to "the Pod starts unmeshed", so check
  that annotation if a workload comes up without its sidecar.
- The Istio and Gateway API route controllers now start based on whether the
  mesh is enabled in this cluster's Signadot configuration, rather than on
  whether the API server serves the corresponding CRDs. A DevMesh-only install
  on a cluster that merely has those CRDs present — easy to end up with, since
  some Kubernetes distributions ship the Gateway API CRDs by default — no longer
  establishes watches on their route objects or runs the periodic cleanup loop
  behind them. That was work the install never asked for, and the Deployment
  stayed Ready throughout, so nothing surfaced it. On an install whose RBAC has
  been trimmed to what the operator actually uses, it also logged repeated
  permission errors; those stop too.
- The agent's `pods/log` grant moves out of the `signadot-agent-namespaced`
  ClusterRole into a `signadot-agent-podlog` ClusterRole of its own, with a
  matching ClusterRoleBinding, or per-namespace RoleBindings when
  `allowedNamespaces` is set. Access is unchanged by default; the split is what
  lets `controlPlane.podLogAccess.enabled: false` withhold it. Expect the new
  objects in an upgrade diff.
- Several unused RBAC grants are gone. The `traffic-manager` ClusterRole no
  longer asks for the cluster token Secret or the `cluster-config` ConfigMap,
  and the `signadot-agent` Role drops `list` and `watch` on `cluster-config`,
  keeping `get`. Both pods read those objects through their projected volume
  rather than through the API, and `resourceNames` never permitted `list` or
  `watch` in the first place, so nothing changes functionally.

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
| `imagePullSecrets`   | List of image pull secret names for all deployments       | `[]`     |


### Image and replicas customization parameters

The parameters in the table below allow one to specify image names for the
images used in our operator.  For each image, the image label `vX.Y.Z` refers to
the [operator version](https://www.signadot.com/docs/operator-version-policy).
Some images may be slated for deprecation, in particular those with the suffix
`-legacy` in their name.

#### Image source

Every operator and injected-sidecar image is composed as
`[registry/]repository/<name>:<tag>`, where `<name>` is fixed per component
(e.g. `agent`, `controller-manager`). The segments are set globally:

| Name         | Description                                                                 | Default     |
| ------------ | --------------------------------------------------------------------------- | ----------- |
| `registry`   | Registry host for all images; empty implies `docker.io`. e.g. `ghcr.io`     | `""`        |
| `repository` | Org/namespace for all images; may be multi-segment, e.g. `ghcr.io/acme`     | `signadot`  |
| `imageTag`   | Tag for all images                                                          | chart appVersion |

For example, `--set registry=ghcr.io --set repository=acme/signadot` yields
`ghcr.io/acme/signadot/agent:vX.Y.Z` for the agent, and likewise for every other
component.

Per-component overrides take precedence over the global segments, most specific
first: a component's `image` (a full ref) replaces all of the above for that
component, and a component's `imageTag` overrides just the tag.

| Name                                  | Description                                              | Default                                |
| ------------------------------------- | -------------------------------------------------------- | -------------------------------------- |
| `controllerManager.replicas`          | Number of replicas for the Controller Manager deployment | `2`                                    |
| `controllerManager.image`             | Controller Manager image override                        | `signadot/controller-manager:vX.Y.Z`   |
| `controllerManager.imagePullPolicy`   | Controller Manager image pull policy                     | `IfNotPresent`                         |
| `agent.image`                         | Agent image override                                     | `signadot/agent:vX.Y.Z`                |
| `agent.imagePullPolicy`               | Agent image pull policy                                  | `IfNotPresent`                         |
| `routeServer.image`                   | Route Server image override                              | `signadot/route-server:vX.Y.Z`         |
| `routeServer.imagePullPolicy`         | Route Server image pull policy                           | `IfNotPresent`                         |
| `ioContextServer.replicas`            | Number of replicas for the IO Context Server deployment  | `1`                                    |
| `ioContextServer.image`               | IO Context Server image override                         | `signadot/io-context-server:vX.Y.Z`    |
| `ioContextServer.imagePullPolicy`     | IO Context Server image pull policy                      | `IfNotPresent`                         |
| `routeInit.image`                     | Route Init container image override                      | `signadot/route-sidecar-init:vX.Y.Z`   |
| `routeInit.imagePullPolicy`           | Route Init container image pull policy                   | `IfNotPresent`                         |
| `routeInit.imagePullSecret`           | Route Init container image pull secret                   | `""`                                   |
| `routeSidecar.image`                  | Route Sidecar container image override                   | `signadot/route-sidecar:vX.Y.Z`        |
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
| `trafficManager.replicas`             | Number of replicas for the Traffic Manager deployment    | `2`                                    |
| `trafficManager.image`                | Traffic Manager image override                           | `signadot/traffic-manager:vX.Y.Z`      |
| `trafficManager.imagePullPolicy`      | Traffic Manager image pull policy                        | `IfNotPresent`                         |
| `devMesh.enabled`                     | Install DevMesh sidecar injection (see note below)       | `true`                                 |
| `previewServer.enabled`               | Serve previews for this cluster (see note below)         | `true`                                 |
| `previewServer.customDomain`          | Base domain preview URLs are reported on                 | `""`                                   |
| `previewServer.replicas`              | Number of replicas for the Preview Server deployment     | `1`                                    |
| `previewServer.image`                 | Preview Server image override                            | `signadot/previewserver:vX.Y.Z`        |
| `previewServer.imagePullPolicy`       | Preview Server image pull policy                         | `IfNotPresent`                         |
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
manner, primarily benefiting DevMesh injection.

ℹ️ `devMesh.enabled: false` installs none of the DevMesh injection webhook — no
`MutatingWebhookConfiguration`, no webhook Service, and no ClusterRole granting
cluster-wide `namespaces` read. Use it where routing is handled another way. See
[Not installing the webhook](#not-installing-the-webhook) for what it costs.

ℹ️ `previewServer` is where previews are configured for a cluster, and the only
place. Both values are rendered into the `cluster-config` ConfigMap, which the
control plane reads, so one setting governs what is installed and what is
served.

`previewServer.enabled: false` installs none of the in-cluster preview server —
no Deployment, Service, ServiceAccount or RBAC — and the control plane refuses
preview requests for this cluster rather than forwarding them to a Service that
is not there.

`previewServer.customDomain` is the base domain this cluster's preview URLs are
reported on, e.g. `preview.example.com`. Setting one says your own ingress
fronts the preview server on that domain; the ingress and its wildcard
certificate are yours to provide. It requires `enabled: true` — a domain with
nothing installed behind it has nothing to serve it, so the combination is
rejected at render time. To stop reporting previews on your domain, remove the
value.


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
  memory: 1Gi
requests:
  memory: 128Mi
```

</td>
</tr>
<tr>
<td>

`routeServer.resources`

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

`previewServer.resources`

</td>
<td>
Preview Server resources
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


### Log level parameters

The parameters below set the log level for each Signadot Operator component.
Valid values are `debug`, `info`, `warn`, and `error`. Unset means `info`.

For the injected containers (`routeSidecar`, `ioSidecar`, `jobExecutor`,
`jobExecutorProxy`), the Helm value is the operator-wide default applied
to every injected pod. Individual pods can override it without
redeploying by setting the annotation `signadot.com/log-level` on the
workload's pod template. Value syntax:

    signadot.com/log-level: <default-level>[,<container>=<level>]*

A bare value applies the level to every signadot-managed container in
the pod. The annotation has no effect on containers signadot does not
manage — most importantly, the main container of a regular workload
pod (your application) is not signadot-managed, so a bare `warn` on
such a pod only affects the injected `sd-sidecar`.

Per-container overrides may follow as comma-separated
`<container>=<level>` pairs, where `<container>` is the actual
Kubernetes container name as it appears in the pod's PodSpec. The
override is mainly useful in pods with more than one signadot-managed
container (job or execunit pods). For example, on a job pod, to quiet
the job-executor proxy but keep the main container at debug:

    signadot.com/log-level: warn,my-main-container=debug

| Name                          | Description                                                                              | Default |
| ----------------------------- | ---------------------------------------------------------------------------------------- | ------- |
| `controllerManager.logLevel`  | Controller Manager log level. Maps to controller-runtime's zap level.                    | `info`  |
| `agent.logLevel`              | Agent log level.                                                                         | `info`  |
| `routeServer.logLevel`        | Route Server log level.                                                                  | `info`  |
| `trafficManager.logLevel`     | Traffic Manager log level.                                                               | `info`  |
| `ioContextServer.logLevel`    | IO Context Server log level.                                                             | `info`  |
| `tunnel.api.logLevel`         | Tunnel API log level.                                                                    | `info`  |
| `tunnel.proxy.logLevel`       | Tunnel Proxy log level.                                                                  | `info`  |
| `previewServer.logLevel`      | Preview Server log level.                                                                | `info`  |
| `routeSidecar.logLevel`       | Default log level for the injected DevMesh `sd-sidecar` container in workload pods.      | `info`  |
| `ioSidecar.logLevel`          | Default log level for the injected `io-sidecar` container in execunit pods.              | `info`  |
| `jobExecutor.logLevel`        | Default log level for the `job-executor` main container in job pods.                     | `info`  |
| `jobExecutorProxy.logLevel`   | Default log level for the injected `job-executor-proxy` container in job pods.           | `info`  |


### Scheduling parameters

The parameters below allow you to control which nodes Signadot Operator components run on.

| Name                            | Description                                               | Default |
| ------------------------------- | --------------------------------------------------------- | ------- |
| `agent.nodeAffinity`            | Node affinity rules for the Agent pod                     | `{}`    |
| `agent.tolerations`             | Tolerations for the Agent pod                             | `[]`    |
| `ioContextServer.nodeAffinity`  | Node affinity rules for the IO Context Server pod         | `{}`    |
| `ioContextServer.tolerations`   | Tolerations for the IO Context Server pod                 | `[]`    |
| `routeServer.nodeAffinity`      | Node affinity rules for the Route Server pod              | `{}`    |
| `routeServer.tolerations`       | Tolerations for the Route Server pod                      | `[]`    |
| `controllerManager.nodeAffinity`| Node affinity rules for the Controller Manager pod        | `{}`    |
| `controllerManager.tolerations` | Tolerations for the Controller Manager pod                | `[]`    |
| `trafficManager.nodeAffinity`   | Node affinity rules for the Traffic Manager pod           | `{}`    |
| `trafficManager.tolerations`    | Tolerations for the Traffic Manager pod                   | `[]`    |
| `tunnel.api.nodeAffinity`       | Node affinity rules for the Tunnel API pod                | `{}`    |
| `tunnel.api.tolerations`        | Tolerations for the Tunnel API pod                        | `[]`    |
| `tunnel.proxy.nodeAffinity`     | Node affinity rules for the Tunnel Proxy pod              | `{}`    |
| `tunnel.proxy.tolerations`      | Tolerations for the Tunnel Proxy pod                      | `[]`    |
| `previewServer.nodeAffinity`    | Node affinity rules for the Preview Server pod            | `{}`    |
| `previewServer.tolerations`     | Tolerations for the Preview Server pod                    | `[]`    |

Example:

```yaml
agent:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "signadot"
    effect: "NoSchedule"
```


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
| `tunnel.config.disableSSH`               | Disable the SSH reverse tunnel endpoint in Tunnel Proxy                                                                                                                                                                                                                      | `false` |
| `tunnel.config.disableXAP`               | Disable the XAP reverse tunnel endpoint in Tunnel Proxy                                                                                                                                                                                                                      | `false` |

### Istio parameters

When Istio is enabled (`istio.enabled: true`), the Signadot Operator manipulates Istio VirtualServices by applying new HTTPRoutes where appropriate to direct traffic to sandboxed workloads. You can configure the operator to add labels and annotations to these objects when they are in use by the operator.  Note that these labels and annotations are only added when the object comes into use. This can be useful for temporarily disabling CI sync, amongst other possibilities.

Enabling Istio will activate the Istio proxy in the following components: in Signadot `agent` (for control-plane access to the cluster), in `tunnel-proxy` (to allow workstation access to the cluster via `signadot local connect`), and in the managed job runner group (for executing in-cluster smart tests).

| Name                                          | Description                                                        | Default                               |
| --------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------- |
| `istio.enabled`                               | Enable Istio integration                                           | `false`                               |
| `istio.gatewayAPI.enabled`                    | Enable Gateway API with Istio                                      | `false`                               |
| `istio.gatewayAPI.preservedAnnotations`       | Glob patterns for baseline annotations to preserve on derived routes | `[]`                                |
| `istio.gatewayAPI.preservedLabels`            | Glob patterns for baseline labels to preserve on derived routes    | `[]`                                  |
| `istio.operator.podLabels`                    | Pod Labels to add to signadot components which should use Istio    | `{"sidecar.istio.io/inject": "true"}` |
| `istio.additionalAnnotations`                 | Annotations to add to istio VirtualServices if not present         | `{}`                                  |
| `istio.additionalLabels`                      | Labels to add to istio VirtualServices if not present              | `{}`                                  |


### Linkerd parameters

Enabling Linkerd will activate the Linkerd proxy in the following components: in Signadot `agent` (for control-plane access to the cluster), in `tunnel-proxy` (to allow workstation access to the cluster via `signadot local connect`), and in the managed job runner group (for executing in-cluster smart tests).

Note that sandbox routing is never expressed via Linkerd's own CRDs. With `linkerd.gatewayAPI.enabled`, routing is expressed as Gateway API `HTTPRoute` and `GRPCRoute` resources; without it, routing relies on the DevMesh sidecars in the relevant workloads, so `devMesh.enabled` must stay `true`.

| Name                                           | Description                                                            | Default                            |
| ---------------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------- |
| `linkerd.enabled`                              | Enable Linkerd integration                                             | `false`                            |
| `linkerd.gatewayAPI.enabled`                   | Enable Gateway API with Linkerd                                        | `false`                            |
| `linkerd.gatewayAPI.preservedAnnotations`      | Glob patterns for baseline annotations to preserve on derived routes   | `[]`                               |
| `linkerd.gatewayAPI.preservedLabels`           | Glob patterns for baseline labels to preserve on derived routes        | `[]`                               |
| `linkerd.operator.podAnnotations`              | Pod Annotations to add to signadot components which should use Linkerd | `{"linkerd.io/inject": "enabled"}` |


### Routing parameters

| Name                    | Description                                                                           | Default  |
| ----------------------- | ------------------------------------------------------------------------------------- | -------- |
| `routing.iptablesMode`  | `iptables` variant to use when configuring rules (possible values: `legacy` or `nft`). Set `legacy` on legacy-iptables hosts (e.g. Amazon Linux 2). | `nft` |
| `routing.customHeaders` | List of custom headers used for sandbox routing                                       | `[]`     |
| `routeServer.legacyRoutesAPI.enabled` | Serve the legacy routes API (see note below)                            | `false`  |

ℹ️ The Route Server publishes its routes over gRPC on port 7777 and HTTP on
port 7778. Port 8080 additionally carries a legacy routes API, kept for
clients predating the current Route Server — old injected route sidecars, and
anything reading routes from
`/apis/apps/v1/namespaces/<ns>/deployments/<name>/routes` or
`/api/v2/namespaces/<ns>/workloads/<uid>/routes` directly. It no longer serves
by default: every request to port 8080 answers `410 Gone` unless
`routeServer.legacyRoutesAPI.enabled` is set to `true`. The flag exists to
carry an install through one release while such clients are upgraded, and the
legacy API is removed in the next release. Prometheus scrapes should use the
`routeserver-metrics` Service on port 9090, which is unaffected, and health
checks should use `/healthz` on port 7778 — the `/healthz` on 8080 belongs to
the legacy server and is gated with it.


### Traffic Manager parameters

| Name                     | Description            | Default |
| ------------------------ | ---------------------- | ------- |
| `trafficManager.enabled` | Enable traffic manager | `true`  |


### Traffic Capture parameters

| Name                                  | Description                                                 | Default |
| ------------------------------------- | ----------------------------------------------------------- | ------- |
| `trafficCapture.enabled`              | Enable traffic capture                                      | `true`  |
| `trafficCapture.requestHeadersElide`  | List of request headers to be elided from traffic captures  | `[]`    |
| `trafficCapture.responseHeadersElide` | List of response headers to be elided from traffic captures | `[]`    |

### Control Plane parameters

| Name                        | Description                                                                                                  | Default                                                         |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------- |
| `controlPlane.tokenSecret`  | Name of the Secret in the signadot namespace which contains the cluster token                                | `cluster-token` (or `cluster-agent` for existing installations) |
| `controlPlane.clusterToken` | Cluster token for connecting the operator to the Signadot Control Plane                                                           | unspecified                                                     |
| `controlPlane.proxy`        | Enable [control plane proxy](https://www.signadot.com/docs/concepts/architecture/control-plane#proxy-server) | `enabled`                                                       |
| `controlPlane.podLogAccess.enabled` | Grant the agent `pods/log`, which backs the pod log views in the Signadot dashboard and CLI. Set to `false` to withhold it | `true`                                          |

Setting `controlPlane.podLogAccess.enabled: false` installs neither the
`signadot-agent-podlog` ClusterRole nor any binding to it, so the Signadot
control plane cannot read pod logs from this cluster, and the pod log views in
the dashboard and CLI stop working. Pod logs stay available through `kubectl` and
whatever logging pipeline the cluster already has.

This gates *reading pod logs* through the Kubernetes log API; it is not a log
egress switch. Job output still leaves the cluster (captured by the job runner,
not read back from the log API), as does traffic capture.

Only a YAML boolean `false` disables it — an unrecognized value leaves access
enabled — so verify against the cluster rather than the values file:

```sh
kubectl auth can-i get pods --subresource=log \
  --as=system:serviceaccount:signadot:agent -n <namespace>
```
