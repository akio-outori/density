APP="density"
#DOCKER_IP = $(shell minikube ip)
#export DOCKER_HOST=tcp://$(DOCKER_IP):2376
#export DOCKER_API_VERSION := 1.35
#export DOCKER_TLS_VERIFY  := 1
#export DOCKER_CERT_PATH   := $(HOME)/.minikube/certs

all: setup build deploy

aws: setup-aws setup-helm setup-prometheus setup-metrics-server setup-custom-metrics build-aws

build:
	@echo docker ip: $(DOCKER_IP)
	@echo docker host: $(DOCKER_HOST)
	@echo docker api version: $(DOCKER_API_VERSION)
	@echo docker tls verify: $(DOCKER_TLS_VERIFY)
	@echo docker cert path: $(DOCKER_CERT_PATH)
	cd docker/app_a/ && docker build --tag $(APP)/app_a:latest .
	cd docker/app_b/ && docker build --tag $(APP)/app_b:latest .

build-aws:
	cd docker/app_a && docker build --tag 134451034775.dkr.ecr.us-east-1.amazonaws.com/density/app_a:latest .
	cd docker/app_b && docker build --tag 134451034775.dkr.ecr.us-east-1.amazonaws.com/density/app_b:latest .
	docker push 134451034775.dkr.ecr.us-east-1.amazonaws.com/density/app_a:latest
	docker push 134451034775.dkr.ecr.us-east-1.amazonaws.com/density/app_b:latest

setup:
	minikube start --memory 4096 --logtostderr
	minikube addons enable metrics-server
	minikube addons enable heapster

setup-aws:
	cd cloudformation && yes | sceptre launch demo
	aws eks --region us-east-1 update-kubeconfig --name density
	kubectl apply -Rf kubernetes/aws

setup-helm:
	kubectl -n kube-system create serviceaccount tiller
	kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
	helm init --service-account tiller
	kubectl -n kube-system  rollout status deploy/tiller-deploy
	helm version

setup-prometheus:
	helm install --name mon --namespace monitoring stable/prometheus-operator --set prometheus.prometheusSpec.serviceMonitorNamespaceSelector.matchNames[0]=default
	kubectl --namespace monitoring get pods -l "release=mon"

setup-metrics-server:
	helm install stable/metrics-server --name metrics-server --namespace kube-system
	kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jq .

setup-custom-metrics:
	helm install -f kubernetes/prometheus-custom-metrics.yaml stable/prometheus-adapter --name prometheus-adapter --namespace kube-system
	kubectl -n kube-system rollout status deploy/prometheus-adapter
	kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1 | jq .

setup-cluster-autoscaler:
	helm install -f kubernetes/cluster-autoscaler.yaml stable/cluster-autoscaler --name cluster-autoscaler --namespace kube-system
	kubectl -n kube-system rollout status deploy/cluster-autoscaler

teardown:
	minikube stop
	minikube delete

teardown-aws:
	cd cloudformation && yes | sceptre delete demo/eks-workergroup.yaml
	cd cloudformation && yes | sceptre delete demo/eks-controlplane.yaml

teardown-helm:
	helm delete tiller --purge

teardown-prometheus:
	helm delete mon --purge

teardown-metrics-server:
	helm delete metrics-server --purge

teardown-custom-metrics:
	helm delete prometheus-adapter --purge

deploy:
	kubectl apply -Rf kubernetes/$(APP)

redeploy: build
	kubectl delete -Rf kubernetes/$(APP)
	kubectl apply -Rf kubernetes/$(APP)
