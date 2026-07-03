{{/*
valuesDefault - traverse .Values along a key path and return the leaf
value (as YAML), or the default if any key along the path is missing.
Uses hasKey, so leaf values of 0, false, or "" are returned unchanged
instead of falling back to the default.
Usage: {{ include "valuesDefault" (list .Values "defaultValue" "path" "to" "value") }}
*/}}
{{- define "valuesDefault" }}
  {{- $it := first . }}
  {{- $retValue := first (rest .) }}
  {{- $found := true }}
  {{- range $key := (rest (rest .)) }}
     {{- if hasKey $it $key }}{{- $it = get $it $key }}
     {{- else }}{{- $found = false }}{{- break }}{{- end }}
  {{- end }}
  {{- if $found }}{{- $it | toYaml }}{{- else }}{{- $retValue }}{{- end }}
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
gatewayAPIPreservedAnnotations - get preservedAnnotations from the mesh that has gatewayAPI enabled
Returns "[]" or a newline followed by the indented YAML list (indent 6).
Usage: {{ include "gatewayAPIPreservedAnnotations" .Values }}
*/}}
{{- define "gatewayAPIPreservedAnnotations" -}}
{{- $istioGW := and (hasKey . "istio") (hasKey .istio "enabled") .istio.enabled (hasKey .istio "gatewayAPI") (hasKey .istio.gatewayAPI "enabled") .istio.gatewayAPI.enabled -}}
{{- $linkerdGW := and (hasKey . "linkerd") (hasKey .linkerd "enabled") .linkerd.enabled (hasKey .linkerd "gatewayAPI") (hasKey .linkerd.gatewayAPI "enabled") .linkerd.gatewayAPI.enabled -}}
{{- if and $istioGW (hasKey .istio.gatewayAPI "preservedAnnotations") .istio.gatewayAPI.preservedAnnotations -}}
{{ printf "\n" }}{{ toYaml .istio.gatewayAPI.preservedAnnotations | indent 6}}
{{- else if and $linkerdGW (hasKey .linkerd.gatewayAPI "preservedAnnotations") .linkerd.gatewayAPI.preservedAnnotations -}}
{{ printf "\n" }}{{ toYaml .linkerd.gatewayAPI.preservedAnnotations | indent 6}}
{{- else -}}
[]
{{- end -}}
{{- end }}

{{/*
gatewayAPIPreservedLabels - get preservedLabels from the mesh that has gatewayAPI enabled
Returns "[]" or a newline followed by the indented YAML list (indent 6).
Usage: {{ include "gatewayAPIPreservedLabels" .Values }}
*/}}
{{- define "gatewayAPIPreservedLabels" -}}
{{- $istioGW := and (hasKey . "istio") (hasKey .istio "enabled") .istio.enabled (hasKey .istio "gatewayAPI") (hasKey .istio.gatewayAPI "enabled") .istio.gatewayAPI.enabled -}}
{{- $linkerdGW := and (hasKey . "linkerd") (hasKey .linkerd "enabled") .linkerd.enabled (hasKey .linkerd "gatewayAPI") (hasKey .linkerd.gatewayAPI "enabled") .linkerd.gatewayAPI.enabled -}}
{{- if and $istioGW (hasKey .istio.gatewayAPI "preservedLabels") .istio.gatewayAPI.preservedLabels -}}
{{ printf "\n" }}{{ toYaml .istio.gatewayAPI.preservedLabels | indent 6}}
{{- else if and $linkerdGW (hasKey .linkerd.gatewayAPI "preservedLabels") .linkerd.gatewayAPI.preservedLabels -}}
{{ printf "\n" }}{{ toYaml .linkerd.gatewayAPI.preservedLabels | indent 6}}
{{- else -}}
[]
{{- end -}}
{{- end }}

{{/*
getAllowedNamespaces - get allowed namespaces, always including signadot
*/}}
{{- define "getAllowedNamespaces" -}}
{{- if .Values.allowedNamespaces }}
  {{- $userNamespaces := .Values.allowedNamespaces -}}
  {{- if not (has "signadot" $userNamespaces) }}
    {{- $userNamespaces = append $userNamespaces "signadot" -}}
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
  {{- $found := true }}
  {{- range $key := (rest .) }}
     {{- if hasKey $it $key }}{{- $it = get $it $key }}
     {{- else }}{{- $found = false }}{{- break }}{{- end }}
  {{- end }}
  {{- if $found }}{{- $it | mustToJson }}{{- end }}
{{- end }}

{{/*
valuesDefaultStr - like valuesDefault but returns string value or empty string
Usage: {{ include "valuesDefaultStr" (list .Values "path" "to" "value") }}
*/}}
{{- define "valuesDefaultStr" }}
  {{- $it := first . }}
  {{- $found := true }}
  {{- range $key := (rest .) }}
     {{- if hasKey $it $key }}{{- $it = get $it $key }}
     {{- else }}{{- $found = false }}{{- break }}{{- end }}
  {{- end }}
  {{- if $found }}{{- $it }}{{- end }}
{{- end }}

{{/*
valuesGetStr - traverse .Values along a key path and return the leaf as a raw
string, or the default if any key along the path is missing.

Like valuesDefault (takes a default, traverses the path), but emits the leaf
verbatim instead of YAML-encoding it. valuesDefault's toYaml can add quoting,
escaping, or a trailing newline — fine when the result is a whole field, but
corrupting when the value is interpolated into a larger string (here, composing
"[registry/]repository/<name>:<tag>" in operatorImage).

Differs from valuesDefaultStr only in taking a default: when the path is missing
valuesDefaultStr yields "" while this yields the supplied default. Both use
hasKey, so a present-but-empty leaf ("") is returned as "" by either — an
explicit `registry: ""` is honored and is distinct from the key being absent.
Usage: {{ include "valuesGetStr" (list .Values "defaultValue" "path" "to" "value") }}
*/}}
{{- define "valuesGetStr" -}}
  {{- $it := first . -}}
  {{- $ret := first (rest .) -}}
  {{- $found := true -}}
  {{- range $key := (rest (rest .)) -}}
     {{- if hasKey $it $key }}{{- $it = get $it $key -}}
     {{- else }}{{- $found = false }}{{- break }}{{- end -}}
  {{- end -}}
  {{- if $found }}{{- $it -}}{{- else }}{{- $ret -}}{{- end -}}
{{- end -}}

{{/*
operatorImage - resolve a component's image ref.
Precedence (most specific wins):
  1. <component>.image          full ref, used verbatim
  2. composed: [registry/]repository/<name>:<tag>, where
       registry   = .Values.registry   (default arg; empty omits the host segment)
       repository = .Values.repository  (default arg)
       tag        = <component>.imageTag || .Values.imageTag || default arg
Usage: {{ include "operatorImage" (list .Values <defRegistry> <defRepository> <defTag> <imageName> <componentKey...>) }}
*/}}
{{- define "operatorImage" -}}
  {{- $values := index . 0 -}}
  {{- $defRegistry := index . 1 -}}
  {{- $defRepository := index . 2 -}}
  {{- $defTag := index . 3 -}}
  {{- $name := index . 4 -}}
  {{- $path := slice . 5 -}}
  {{- $override := include "valuesDefaultStr" (concat (list $values) $path (list "image")) -}}
  {{- if ne $override "" -}}
    {{- $override -}}
  {{- else -}}
    {{- $registry := include "valuesGetStr" (list $values $defRegistry "registry") -}}
    {{- $repository := include "valuesGetStr" (list $values $defRepository "repository") -}}
    {{- $tag := include "valuesDefaultStr" (concat (list $values) $path (list "imageTag")) -}}
    {{- if eq $tag "" -}}{{- $tag = include "valuesDefaultStr" (list $values "imageTag") -}}{{- end -}}
    {{- if eq $tag "" -}}{{- $tag = $defTag -}}{{- end -}}
    {{- if ne $registry "" -}}{{- printf "%s/" $registry -}}{{- end -}}
    {{- printf "%s/%s:%s" $repository $name $tag -}}
  {{- end -}}
{{- end -}}

{{/*
tokenSecretName - get the token secret name
Checks .Values.controlPlane.tokenSecret, then looks up existing "cluster-agent" secret,
then falls back to "cluster-token"
*/}}
{{- define "tokenSecretName" -}}
{{- $oldSecret := (lookup "v1" "Secret" "signadot" "cluster-agent") -}}
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
    preservedAnnotations: {{ include "gatewayAPIPreservedAnnotations" .Values }}
    preservedLabels: {{ include "gatewayAPIPreservedLabels" .Values }}
  iptablesMode: {{ if and (hasKey .Values "routing") (hasKey .Values.routing "iptablesMode") -}}{{ .Values.routing.iptablesMode }}{{- else -}}nft{{- end }}
  customHeaders: {{ with .Values }}{{ with .routing }}{{ with .customHeaders }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
{{- $defaultHeaders := include "valuesDefaultJson" (list .Values "routing" "defaultHeaders") }}
{{- if $defaultHeaders }}
  defaultHeaders: {{ $defaultHeaders }}
{{- end }}
trafficManager:
  enabled: {{ if and (hasKey .Values "trafficManager") (hasKey .Values.trafficManager "enabled") -}}{{ toString .Values.trafficManager.enabled }}{{- else -}}true{{- end }}
trafficCapture:
  enabled: {{ if and (hasKey .Values "trafficCapture") (hasKey .Values.trafficCapture "enabled") -}}{{ toString .Values.trafficCapture.enabled }}{{- else -}}true{{- end }}
  requestHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .requestHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
  responseHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .responseHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
{{- end -}}
