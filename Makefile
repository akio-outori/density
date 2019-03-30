APP="density"
DOCKER_IP = $(shell minikube ip)
export DOCKER_HOST=tcp://$(DOCKER_IP):2376
export DOCKER_API_VERSION := 1.35
export DOCKER_TLS_VERIFY  := 1
export DOCKER_CERT_PATH   := $(HOME)/.minikube/certs

all: setup build deploy

aws: setup-aws build-aws

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
	cd cloudformations && y | sceptre launch demo
	kubectl apply -Rf kubernetes/aws
	kubectl create namespace monitoring
	kubectl create namespace custom-metrics
	openssl req -newkey rsa:2048 -nodes -keyout serving.key -x509 -days 365 -out serving.crt
	kubectl create secret generic cm-adapter-serving-certs --from-file=./serving.crt --from-file=./serving.key -n custom-metrics
	rm -f serving.key serving.crt

teardown:
	minikube stop
	minikube delete

deploy:
	kubectl apply -Rf kubernetes/$(APP)

redeploy: build
	kubectl delete -Rf kubernetes/$(APP)
	kubectl apply -Rf kubernetes/$(APP)
