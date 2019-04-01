APP="density"

minikube: setup build deploy
aws: setup-aws setup-helm setup-metrics-server setup-cluster-autoscaler setup-prometheus setup-custom-metrics build-aws deploy

build:
	DOCKER_IP = $(shell minikube ip)
	export DOCKER_HOST=tcp://$(DOCKER_IP):2376
	export DOCKER_API_VERSION := 1.35
	export DOCKER_TLS_VERIFY  := 1
	export DOCKER_CERT_PATH   := $(HOME)/.minikube/certs
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
	cd cloudformation && yes | sceptre launch demo/eks-iam.yaml
	cd cloudformation && yes | sceptre launch demo/eks-controlplane.yaml
	cd cloudformation && yes | sceptre launch demo/eks-workergroup.yaml
	aws eks --region us-east-1 update-kubeconfig --name density
	kubectl apply -Rf kubernetes/aws

setup-helm:
	kubectl -n kube-system create serviceaccount tiller
	kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
	helm init --service-account tiller
	kubectl -n kube-system  rollout status deploy/tiller-deploy
	helm version

setup-prometheus:
	helm install stable/prometheus-operator --name mon --namespace monitoring --set prometheus.prometheusSpec.serviceMonitorNamespaceSelector.matchNames[0]=default
	kubectl -n monitoring rollout status deploy/mon-prometheus-operator-operator && sleep 60
	kubectl --namespace monitoring get pods -l "release=mon"

setup-metrics-server:
	helm install stable/metrics-server --name metrics-server --namespace kube-system
	kubectl -n kube-system rollout status deploy/metrics-server && sleep 60
	kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jq .

setup-custom-metrics:
	helm install -f kubernetes/prometheus-custom-metrics.yaml stable/prometheus-adapter --name prometheus-adapter --namespace kube-system
	kubectl -n kube-system rollout status deploy/prometheus-adapter && sleep 60
	kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1 | jq .

setup-cluster-autoscaler:
	helm install -f kubernetes/cluster-autoscaler/values-custom.yaml kubernetes/cluster-autoscaler --name cluster-autoscaler --namespace kube-system
	kubectl -n kube-system rollout status deploy/cluster-autoscaler

setup-haproxy:
	helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
	helm install -f kubernetes/haproxy-ingress.yaml incubator/haproxy-ingress --name haproxy-ingress --namespace haproxy-ingress
	kubectl -n kube-system rollout status deploy/haproxy-ingress

teardown:
	minikube stop
	minikube delete

teardown-aws:
	cd cloudformation && yes | sceptre delete demo/eks-workergroup.yaml
	cd cloudformation && yes | sceptre delete demo/eks-controlplane.yaml
	cd cloudformation && yes | sceptre delete demo/eks-iam.yaml

teardown-helm:
	helm delete tiller --purge

teardown-prometheus:
	helm delete mon --purge

teardown-metrics-server:
	helm delete metrics-server --purge

teardown-custom-metrics:
	helm delete prometheus-adapter --purge

teardown-cluster-autoscaler:
	helm delete cluster-autoscaler --purge

teardown-haproxy:
	helm delete haproxy-ingress --purge

deploy:
	kubectl apply -Rf kubernetes/$(APP)

redeploy:
	kubectl delete -Rf kubernetes/$(APP)
	kubectl apply -Rf kubernetes/$(APP)
