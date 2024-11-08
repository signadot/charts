{{/*
cluster config template
*/}}
{{- define "compileClusterConfig" -}}
routing:
  istio:
    enabled: {{ with .Values }}{{ with .istio }}{{ with .enabled }}{{ toString .}}{{- else -}}false{{- end }}{{- else -}}false{{- end }}{{- else -}}false{{- end }}
    enableHostRouting: {{ with .Values }}{{ with .istio }}{{ with .enableDeprecatedHostRouting }}{{ toString .}}{{- else -}}false{{- end }}{{- else -}}false{{- end }}{{- else -}}false{{- end }}
  linkerd:
    enabled: {{ with .Values }}{{ with .linkerd }}{{ with .enabled }}{{ toString .}}{{- else -}}false{{- end }}{{- else -}}false{{- end }}{{- else -}}false{{- end }}
  customHeaders: {{ with .Values }}{{ with .routing }}{{ with .customHeaders }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
trafficCapture:
  requestHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .requestHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
  responseHeadersElide: {{ with .Values }}{{ with .trafficCapture }}{{ with .responseHeadersElide }}{{ printf "\n" }}{{ toYaml . | indent 4}}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}{{- else -}}[]{{- end }}
{{- end -}}