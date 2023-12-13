ISTIO_VERSION="1.19.3"
ISTIO_HELM_REPO="https://istio-release.storage.googleapis.com/charts"
ISTIO_CP_NS="istio-system"
ISTIO_INGRESS_NS="istio-ingress"
ISTIO_EGRESS_NS="istio-egress"

.PHONY: all
all: create-cluster deploy-istio

create-cluster:
	@scripts/print_header.sh "Create KinD cluster"
	@touch kubeconfig
	@chmod 600 kubeconfig
	@KUBECONFIG=kubeconfig kind create cluster --config ./kind/kind-config-istio.yaml

clean:
	@scripts/print_header.sh "Delete KinD cluster"
	@kind delete cluster --name istio
	@rm kubeconfig

deploy-istio: deploy-istio-cp deploy-istio-ingress configure-isto-ingress deploy-istio-egress

deploy-istio-cp:
	@scripts/print_header.sh "Deploy istio control plane"
	@helm install istio-base --repo $(ISTIO_HELM_REPO) base --create-namespace --namespace $(ISTIO_CP_NS) \
        --version $(ISTIO_VERSION)
	@helm install istiod --repo $(ISTIO_HELM_REPO) istiod --namespace $(ISTIO_CP_NS) --version $(ISTIO_VERSION) \
		--values helm/istiod-values.yaml

check-istiod:
	@scripts/print_header.sh "Checking status of istiod pods"
	@scripts/check_pod.sh $(ISTIO_CP_NS) app=istiod

deploy-istio-ingress: check-istiod
	@scripts/print_header.sh "Deploy istio ingress gateway"
	@helm install istio-ingress --repo $(ISTIO_HELM_REPO) gateway --create-namespace --namespace $(ISTIO_INGRESS_NS) \
		--version $(ISTIO_VERSION) --values helm/istio-ingress-values.yaml
	@scripts/print_header.sh "Checking status of istio-ingress pods"
	@scripts/check_pod.sh $(ISTIO_INGRESS_NS) app=istio-ingress

generate-ingress-cert:
	@openssl req -x509 -nodes -days 7 -newkey rsa:2048 -keyout ingress.key -out ingress.crt -subj \
        "/CN=Makefile/O=istio-on-kind" --addext "subjectAltName = DNS:ingress.127-0-0-1.nip.io, \
        DNS:ingress.127.0.0.1.nip.io"
	@kubectl create secret tls --namespace $(ISTIO_INGRESS_NS) gateway-tls --key ingress.key --cert ingress.crt
	@rm ingress.key ingress.crt

configure-isto-ingress: generate-ingress-cert
	@kubectl apply --namespace $(ISTIO_INGRESS_NS) -f manifests/istio-ingress/gateway.yaml

remove-istio-ingress:
	@scripts/print_header.sh "Remove istio ingress gateway"
	@helm uninstall istio-ingress --namespace $(ISTIO_INGRESS_NS)

deploy-istio-egress: check-istiod
	@scripts/print_header.sh "Deploy istio egress gateway"
	@helm install istio-egress --repo $(ISTIO_HELM_REPO) gateway --create-namespace --namespace $(ISTIO_EGRESS_NS) \
        --version $(ISTIO_VERSION)
	@scripts/print_header.sh "Checking status of istio-egress pods"
	@scripts/check_pod.sh $(ISTIO_EGRESS_NS) app=istio-egress

remove-istio-egress:
	@scripts/print_header.sh "Remove istio egress gateway"
	@helm uninstall istio-egress --namespace $(ISTIO_EGRESS_NS)

remove-istio-cp:
	@scripts/print_header.sh "Remove istio control plane"
	@helm uninstall istiod --namespace istio-system
	@helm uninstall istio-base --namespace istio-system
