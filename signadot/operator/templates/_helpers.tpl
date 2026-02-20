{{/*
operator.namespace - get the operator deployment namespace
Defaults to "signadot" for backward compatibility.
Override via .Values.namespace to install into a custom namespace.
*/}}
{{- define "operator.namespace" -}}
{{- .Values.namespace | default "signadot" -}}
{{- end -}}

{{/*
valuesDefault - dig into .Values with a default fallback
Usage: {{ include "valuesDefault" (list .Values "defaultValue" "path" "to" "value") }}
*/}}
{{- define "valuesDefault" }}
  {{- $it := first . }}
  {{- $retValue := first (rest .) }}
  {{- range $key := (slice (rest (rest .))) }}
     {{- $it = (get $it $key) }}
     {{- if (not $it) }}{{- break }}{{- end }}
  {{- end }}
  {{- if $it }}{{- $it | toYaml }}{{- else }}{{- $retValue }}{{- end }}
{{- end }}


{{/*
gatewayAPIEnabled - check if Gateway API routing should be enabled
Returns "true" if either istio or linkerd has both enabled and gatewayAPI.enabled set to true
Usage: {{ include "gatewayAPIEnabled" .Values }}
*/}}
{{- define "gatewayAPIEnabled" -}}
{{- $istioGatewayAPI := and (hasKey . "istio") (hasKey .istio "enabled") .istio.enabled (hasKey .istio "gatewayAPI") (hasKey .istio.gatewayAPI "enabled") .istio.gatewayAPI.enabled -}}
{{- $linkerdGatewayAPI := and (hasKey . "linkerd") (hasKey .linkerd "enabled") .linkerd.enabled (hasKey .linkerd "gatewayAPI") (hasKey .linkerd.gatewayAPI "enabled") .linkerd.gatewayAPI.enabled -}}
{{- if or $istioGatewayAPI $linkerdGatewayAPI -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/*
getAllowedNamespaces - get allowed namespaces, always including the operator namespace
*/}}
{{- define "getAllowedNamespaces" -}}
{{- $operatorNs := include "operator.namespace" . -}}
{{- if .Values.allowedNamespaces }}
  {{- $userNamespaces := .Values.allowedNamespaces -}}
  {{- if not (has $operatorNs $userNamespaces) }}
    {{- $userNamespaces = append $userNamespaces $operatorNs -}}
  {{- end }}
{{- $userNamespaces | toJson -}}
{{- else -}}
[]
{{- end }}
{{- end }}

{{/*
valuesDefaultJson - like valuesDefault but returns JSON-encoded value or empty string
Usage: {{ include "valuesDefaultJson" (list .Values "path" "to" "value") }}
*/}}
{{- define "valuesDefaultJson" }}
  {{- $it := first . }}
  {{- range $key := (slice (rest .)) }}
     {{- $it = (get $it $key) }}
     {{- if (not $it) }}{{- break }}{{- end }}
  {{- end }}
  {{- if $it }}{{- $it | mustToJson }}{{- end }}
{{- end }}

{{/*
valuesDefaultStr - like valuesDefault but returns string value or empty string
Usage: {{ include "valuesDefaultStr" (list .Values "path" "to" "value") }}
*/}}
{{- define "valuesDefaultStr" }}
  {{- $it := first . }}
  {{- range $key := (slice (rest .)) }}
     {{- $it = (get $it $key) }}
     {{- if (not $it) }}{{- break }}{{- end }}
  {{- end }}
  {{- if $it }}{{- $it }}{{- end }}
{{- end }}

{{/*
tokenSecretName - get the token secret name
Checks .Values.controlPlane.tokenSecret, then looks up existing "cluster-agent" secret,
then falls back to "cluster-token"
*/}}
{{- define "tokenSecretName" -}}
{{- $oldSecret := (lookup "v1" "Secret" (include "operator.namespace" .) "cluster-agent") -}}
{{- if and .Values.controlPlane .Values.controlPlane.tokenSecret -}}
{{- .Values.controlPlane.tokenSecret -}}
{{- else if $oldSecret.metadata -}}
{{- $oldSecret.metadata.name -}}
{{- else -}}
cluster-token
{{- end -}}
{{- end }}

{{/*
compileClusterConfig - generate cluster_config.yaml content
*/}}
{{- define "compileClusterConfig" -}}
{{- if and (hasKey .Values "istio") (hasKey .Values.istio "enabled") .Values.istio.enabled
           (hasKey .Values "linkerd") (hasKey .Values.linkerd "enabled") .Values.linkerd.enabled }}
{{- fail "istio and linkerd cannot be enabled at the same time" }}
{{- end }}
{{- if and (hasKey .Values "istio") (hasKey .Values.istio "enableDeprecatedHostRouting") }}
{{- fail "istio.enableDeprecatedHostRouting is no longer supported" }}
{{- end }}
{{- $allowedNamespaces := (include "getAllowedNamespaces" . | fromJsonArray) -}}
allowedNamespaces: {{ if gt (len $allowedNamespaces) 0 }}{{ printf "\n" }}{{ toYaml $allowedNamespaces | indent 2}}{{- else -}}[]{{- end }}
{{- if (hasKey .Values "controlPlane") }}
controlPlane:
{{- if (hasKey .Values.controlPlane "proxy") }}
  proxy: {{ .Values.controlPlane.proxy }}
{{- end }}
{{- if (hasKey .Values.controlPlane "controlAPI") }}
  controlAPI: {{ .Values.controlPlane.controlAPI }}
{{- end }}
{{- if (hasKey .Values.controlPlane "tunnelAddr") }}
  tunnelAddr: {{ .Values.controlPlane.tunnelAddr }}
{{- end }}
{{- if (hasKey .Values.controlPlane "tunnelTLS") }}
  tunnelTLS: {{ .Values.controlPlane.tunnelTLS }}
{{- end }}
{{- if (hasKey .Values.controlPlane "proxyURL") }}
  proxyURL: {{ .Values.controlPlane.proxyURL }}
{{- end }}
{{- if (hasKey .Values.controlPlane "artifactsAPI") }}
  artifactsAPI: {{ .Values.controlPlane.artifactsAPI }}
{{- end }}
{{- if (hasKey .Values.controlPlane "trafficmodelsAPI") }}
  trafficmodelsAPI: {{ .Values.controlPlane.trafficmodelsAPI }}
{{- end }}
{{- end }}
allowOrphanedResources: {{ if hasKey .Values "allowOrphanedResources" -}}{{ toString .Values.allowOrphanedResources }}{{- else -}}false{{- end }}
routing:
  istio:
    enabled: {{ if and (hasKey .Values "istio") (hasKey .Values.istio "enabled") -}}{{ toString .Values.istio.enabled }}{{- else }}false{{- end }}
    operator:
      podLabels:{{- if and (hasKey .Values "istio") (hasKey .Values.istio "operator") (hasKey .Values.istio.operator "podLabels") (.Values.istio.operator.podLabels) }}
{{ toYaml .Values.istio.operator.podLabels | indent 8}}{{- else }}
        sidecar.istio.io/inject: "true"
    {{- end}}
  linkerd:
    enabled: {{ if and (hasKey .Values "linkerd") (hasKey .Values.linkerd "enabled") -}}{{ toString .Values.linkerd.enabled }}{{- else }}false{{- end }}
    operator:
      podAnnotations:{{- if and (hasKey .Values "linkerd") (hasKey .Values.linkerd "operator") (hasKey .Values.linkerd.operator "podAnnotations") (.Values.linkerd.operator.podAnnotations) }}
{{ toYaml .Values.linkerd.operator.podAnnotations | indent 8}}{{- else }}
        linkerd.io/inject: enabled
    {{- end}}
  gatewayAPI:
    enabled: {{ include "gatewayAPIEnabled" .Values }}
  iptablesMode: {{ if and (hasKey .Values "routing") (hasKey .Values.routing "iptablesMode") -}}{{ .Values.routing.iptablesMode }}{{- else -}}legacy{{- end }}
  customHeaders: {{ with .Values }}{{ with .routing }}{{ with .customHeaders }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
trafficManager:
  enabled: {{ if and (hasKey .Values "trafficManager") (hasKey .Values.trafficManager "enabled") -}}{{ toString .Values.trafficManager.enabled }}{{- else -}}true{{- end }}
trafficCapture:
  enabled: {{ if and (hasKey .Values "trafficCapture") (hasKey .Values.trafficCapture "enabled") -}}{{ toString .Values.trafficCapture.enabled }}{{- else -}}true{{- end }}
  requestHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .requestHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
  responseHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .responseHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
{{- end -}}
