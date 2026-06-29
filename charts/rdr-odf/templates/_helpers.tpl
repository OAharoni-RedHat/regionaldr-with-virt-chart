{{/* Cluster names from globals (set by values-cluster-names.yaml via global.*) */}}
{{- define "rdr.primaryClusterName" -}}
{{- .Values.global.primaryClusterName | default "ocp-primary" -}}
{{- end -}}

{{- define "rdr.secondaryClusterName" -}}
{{- .Values.global.secondaryClusterName | default "ocp-secondary" -}}
{{- end -}}

{{/* Preferred cluster for DRPC. Override via rdr-odf.drpc.preferredCluster in override files. */}}
{{- define "rdr.preferredClusterName" -}}
{{- (index (.Values.drpc | default dict) "preferredCluster") | default (include "rdr.primaryClusterName" .) -}}
{{- end -}}

{{/* regionalDR[0].name (ClusterSet name) */}}
{{- define "rdr.regionalDRClusterSetName" -}}
{{- $dr := index .Values.regionalDR 0 -}}
{{- $dr.name -}}
{{- end -}}

{{/* Namespace for ODF CA post-install Jobs */}}
{{- define "rdr.clusterCaMgtNamespace" -}}
{{- .Values.clusterCaMgt.namespace | default "cluster-ca-mgt" -}}
{{- end -}}

{{/* ODF post-install fixes sub-flag. Defaults true when key is absent. */}}
{{- define "rdr.odfPostInstallFixesEnabled" -}}
{{- $odf := .Values.odf | default dict -}}
{{- if not (hasKey $odf "postInstallFixesEnabled") -}}1{{- else if index $odf "postInstallFixesEnabled" -}}1{{- else -}}0{{- end -}}
{{- end -}}

{{/* VM storage class for KubeVirt DR peer class check */}}
{{- define "rdr.vmStorageClassName" -}}
{{- (index (.Values.drpc | default dict) "vmStorageClassName") | default "ocs-storagecluster-ceph-rbd-virtualization" -}}
{{- end -}}

{{/* VM prereq check: returns "1" when the drpolicy has vmSupport=true */}}
{{- define "rdr.drPolicyVmPrereqRequired" -}}
{{- $vmSupport := index . "vmSupport" | default false -}}
{{- if $vmSupport -}}1{{- else -}}0{{- end -}}
{{- end -}}

{{/*
  Stage ConfigMap flat keys into /tmp/regionaldr-ansible (no ansible install).
  Copied from parent chart — no .Files usage, safe to include in subchart.
*/}}
{{- define "rdr.ansibleStageOnly" -}}
set -euo pipefail
export HOME=/tmp
STAGE=/tmp/regionaldr-ansible
rm -rf "$STAGE"
mkdir -p "$STAGE"
shopt -s nullglob
for f in /ansible-cm/*; do
  [[ -f "$f" ]] || continue
  key=$(basename "$f")
  rel=${key//__//}
  mkdir -p "$STAGE/$(dirname "$rel")"
  cp "$f" "$STAGE/$rel"
done
cd "$STAGE"
{{- end }}

{{/* Stage + pip install ansible-core + PATH. */}}
{{- define "rdr.ansibleBootstrap" -}}
{{ include "rdr.ansibleStageOnly" . }}
export ANSIBLE_LOCAL_TMP=/tmp/ansible-tmp
{{- $verbosity := .Values.ansible.verbosity | default 0 | int }}
{{- if gt $verbosity 4 }}{{- $verbosity = 4 }}{{- end }}
{{- if lt $verbosity 0 }}{{- $verbosity = 0 }}{{- end }}
{{- if gt $verbosity 0 }}
export ANSIBLE_VERBOSITY={{ $verbosity }}
{{- end }}
python3 -m pip install --user -q --no-warn-script-location 'ansible-core>=2.15,<2.17'
export PATH="/tmp/.local/bin:$PATH"
{{- end }}

{{/*
  Pod annotation for ansible job drift detection.
  .Files.Glob cannot reach the parent chart's ansible/ directory from a subchart,
  so this is a no-op here. The regionaldr-ansible ConfigMap itself triggers pod
  replacement when its content changes (ArgoCD ServerSideApply).
*/}}
{{- define "rdr.ansibleJobPodAnnotations" -}}
{{- end -}}
