
{{/*
cluster config template
*/}}
{{- define "compileClusterConfig" -}}
{{- $allowedNamespaces := (include "getAllowedNamespaces" . | fromJsonArray) -}}
allowedNamespaces: {{ if gt (len $allowedNamespaces) 0 }}{{ printf "\n" }}{{ toYaml $allowedNamespaces | indent 2}}{{- else -}}[]{{- end }}
routing:
  istio:
    enabled: {{ if and (hasKey .Values "istio") (hasKey .Values.istio "enabled") -}}{{ toString .Values.istio.enabled }}{{- else -}}false{{- end }}
    enableHostRouting: {{ if and (hasKey .Values "istio") (hasKey .Values.istio "enableDeprecatedHostRouting") -}}{{ toString .Values.istio.enableDeprecatedHostRouting }}{{- else -}}false{{- end }}
  linkerd:
    enabled: {{ if and (hasKey .Values "linkerd") (hasKey .Values.linkerd "enabled") -}}{{ toString .Values.linkerd.enabled }}{{- else -}}false{{- end }}
  customHeaders: {{ with .Values }}{{ with .routing }}{{ with .customHeaders }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
sandboxTrafficManager:
  enabled: {{ if and (hasKey .Values "sandboxTrafficManager") (hasKey .Values.sandboxTrafficManager "enabled") -}}{{ toString .Values.sandboxTrafficManager.enabled }}{{- else -}}true{{- end }}
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