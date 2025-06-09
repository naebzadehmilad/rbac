#!/bin/bash

NEW_USER="p.arazesh"
NAMESPACE="kube-system"
CONFIG_FILE="${NEW_USER}-config.yaml"

kubectl create serviceaccount "${NEW_USER}" -n "${NAMESPACE}"

kubectl create clusterrolebinding "${NEW_USER}-binding" \
  --clusterrole=cluster-admin \
  --serviceaccount="${NAMESPACE}:${NEW_USER}"

TOKEN=$(kubectl -n "${NAMESPACE}" create token "${NEW_USER}" --duration=87600h)

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

cat <<EOF > "${CONFIG_FILE}"
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    certificate-authority-data: ${CA_DATA}
    server: ${SERVER}
contexts:
- name: ${NEW_USER}-context
  context:
    cluster: kubernetes
    user: ${NEW_USER}
current-context: ${NEW_USER}-context
users:
- name: ${NEW_USER}
  user:
    token: ${TOKEN}
EOF

echo "Kubeconfig '${NEW_USER}': ${CONFIG_FILE}"

kubectl -n kube-system get sa "${NEW_USER}"
