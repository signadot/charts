
{{/*
cluster config template
*/}}
{{- define "compileClusterConfig" -}}
{{- $allowedNamespaces := (include "getAllowedNamespaces" . | fromJsonArray) -}}
allowedNamespaces: {{ if gt (len $allowedNamespaces) 0 }}{{ printf "\n" }}{{ toYaml $allowedNamespaces | indent 2}}{{- else -}}[]{{- end }}
controlPlane:
  proxy: {{ if and (hasKey .Values "controlPlane") (hasKey .Values.controlPlane "proxy") -}}{{ .Values.controlPlane.proxy }}{{- else -}}enabled{{- end }}
  controlAPI: {{ if and (hasKey .Values "controlPlane") (hasKey .Values.controlPlane "controlAPI") -}}{{ .Values.controlPlane.controlAPI }}{{- else -}}https://api.signadot.com{{- end}}
  tunnelAddr: {{ if and (hasKey .Values "controlPlane") (hasKey .Values.controlPlane "tunnelAddr") -}}{{ .Values.controlPlane.tunnelAddr }}{{- else -}}tunnel.signadot.com:443{{- end}}
{{- if and (hasKey .Values "controlPlane") (hasKey .Values.controlPlane "tunnelTLS") }}
  tunnelTLS: {{ .Values.controlPlane.tunnelTLS }}
{{- end }}
{{- if and (hasKey .Values "controlPlane") (hasKey .Values.controlPlane "artifactsAPI") }}
  artifactsAPI: {{ .Values.controlPlane.artifactsAPI }}
{{- end }}
{{- if and (hasKey .Values "controlPlane") (hasKey .Values.controlPlane "trafficmodelsAPI") }}
  trafficmodelsAPI: {{ .Values.controlPlane.trafficmodelsAPI }}
{{- end }}
allowOrphanedResources: {{ if hasKey .Values "allowOrphanedResources" -}}{{ toString .Values.allowOrphanedResources }}{{- else -}}false{{- end }}
routing:
  istio:
    enabled: {{ if and (hasKey .Values "istio") (hasKey .Values.istio "enabled") -}}{{ toString .Values.istio.enabled }}{{- else }}false{{- end }}
    operator:
      podLabels:{{- if and (hasKey .Values "istio") (hasKey .Values.istio "operator") (hasKey .Values.istio.operator "podLabels") (.Values.istio.operator.podLabels) }}
{{ toYaml .Values.istio.operator.podLabels | indent 8}}{{- else }}
        {{"sidecar.istio.io/inject"}}: {{"true"}}
    {{- end}}
    enableHostRouting: {{ if and (hasKey .Values "istio") (hasKey .Values.istio "enableDeprecatedHostRouting") -}}{{ toString .Values.istio.enableDeprecatedHostRouting }}{{- else }} false{{- end }}
  linkerd:
    enabled: {{ if and (hasKey .Values "linkerd") (hasKey .Values.linkerd "enabled") -}}{{ toString .Values.linkerd.enabled }}{{- else }}false{{- end }}
    operator:
      podAnnotations:{{- if and (hasKey .Values "linkerd") (hasKey .Values.linkerd "operator") (hasKey .Values.linkerd.operator "podAnnotations") (.Values.linkerd.operator.podAnnotations) }}
{{ toYaml .Values.linkerd.operator.podAnnotations | indent 8}}{{- else }}
        {{"linkerd.io/inject"}}: {{"enabled"}}
    {{- end}}
  iptablesMode: {{ if and (hasKey .Values "routing") (hasKey .Values.routing "iptablesMode") -}}{{ .Values.routing.iptablesMode }}{{- else -}}legacy{{- end }}
  customHeaders: {{ with .Values }}{{ with .routing }}{{ with .customHeaders }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
trafficCapture:
  enabled: {{ if and (hasKey .Values "trafficCapture") (hasKey .Values.trafficCapture "enabled") -}}{{ toString .Values.trafficCapture.enabled }}{{- else -}}true{{- end }}
  requestHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .requestHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
  responseHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .responseHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
{{- end -}}


{{/*
get allowed namespaces
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
