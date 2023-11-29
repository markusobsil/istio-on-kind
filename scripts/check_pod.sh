#!/bin/bash

if [ $# -ne 2 ];
then
  echo "ERROR: Need two arguments: NAMESPACE LABEL_SELECTOR"
  exit 1
fi

NAMESPACE=$1
LABEL_SELECTOR=$2
found_pods=false
echo "INFO: Looking for Pods with ${LABEL_SELECTOR} in Namespace ${NAMESPACE}"

for pod in $(kubectl get pods -n "${NAMESPACE}" --selector="${LABEL_SELECTOR}" -o custom-columns=name:metadata.name --no-headers)
do
  kubectl wait --for=condition=ready --namespace "${NAMESPACE}" pod "${pod}" --timeout=90s
  found_pods=true
done

if [ $found_pods = false ]
then
  echo "ERROR: No pods found"
  exit 1
fi
