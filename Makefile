ISTIO_VERSION="1.19.3"
ISTIO_CP_NS="istio-system"
ISTIO_INGRESS_NS="istio-ingress"
ISTIO_EGRESS_NS="istio-egress"

.PHONY: all
all: create-cluster deploy-istio-cp deploy-istio-ingress

create-cluster:
	@script/print_header.sh "Create KinD cluster"
	@touch kubeconfig
	@chmod 600 kubeconfig
	@KUBECONFIG=kubeconfig kind create cluster --config ./kind/kind-config-istio.yaml

clean:
	@script/print_header.sh "Delete KinD cluster"
	@kind delete cluster --name istio
	@rm kubeconfig

deploy-istio-cp:
	@script/print_header.sh "Deploy istio control plane"
	@helm install istio-base istio/base --create-namespace --namespace $(ISTIO_CP_NS) --version $(ISTIO_VERSION)
	@helm install istiod istio/istiod --namespace $(ISTIO_CP_NS) --version $(ISTIO_VERSION) \
		--values helm/istiod-values.yaml

check-istiod:
	@script/print_header.sh "Checking status of istiod pods"
	@script/check_istiod.sh $(ISTIO_CP_NS)

deploy-istio-ingress: check-istiod
	@script/print_header.sh "Deploy istio ingress gateway"
	@helm install istio-ingress istio/gateway --create-namespace --namespace $(ISTIO_INGRESS_NS) \
		--version $(ISTIO_VERSION) --values helm/istio-ingress-values.yaml

remove-istio-ingress:
	@script/print_header.sh "Remove istio ingress gateway"
	@helm uninstall istio-ingress --namespace $(ISTIO_INGRESS_NS)

deploy-istio-egress: check-istiod
	@script/print_header.sh "Deploy istio egress gateway"
	@helm install istio-egress istio/gateway --create-namespace --namespace $(ISTIO_EGRESS_NS) --version $(ISTIO_VERSION)

remove-istio-egress:
	@script/print_header.sh "Remove istio egress gateway"
	@helm uninstall istio-egress --namespace $(ISTIO_EGRESS_NS)

remove-istio-cp:
	@script/print_header.sh "Remove istio control plane"
	@helm uninstall istiod --namespace istio-system
	@helm uninstall istio-base --namespace istio-system
