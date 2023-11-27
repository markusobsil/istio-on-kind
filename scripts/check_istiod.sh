#!/bin/bash

ISTIO_CP_NS=$1

for pod in $(kubectl get pods -n "${ISTIO_CP_NS}" --selector=app=istiod -o custom-columns=name:metadata.name --no-headers)
do
  kubectl wait --for=condition=ready --namespace "${ISTIO_CP_NS}" pod "${pod}" --timeout=60s
done
