APP="density"
DOCKER_IP = $(shell minikube ip)
export DOCKER_HOST=tcp://$(DOCKER_IP):2376
export DOCKER_API_VERSION := 1.35
export DOCKER_TLS_VERIFY  := 1
export DOCKER_CERT_PATH   := $(HOME)/.minikube/certs

all: setup build deploy

build:
	@echo docker ip: $(DOCKER_IP)
	@echo docker host: $(DOCKER_HOST)
	@echo docker api version: $(DOCKER_API_VERSION)
	@echo docker tls verify: $(DOCKER_TLS_VERIFY)
	@echo docker cert path: $(DOCKER_CERT_PATH)
	cd docker/app_a/ && docker build --tag $(APP)/app_a:latest .
	cd docker/app_b/ && docker build --tag $(APP)/app_b:latest .

setup:
	minikube start --logtostderr

teardown:
	minikube stop
	minikube delete

deploy:
	kubectl delete -Rf kubernetes/$(APP)
	kubectl apply -Rf kubernetes/$(APP)
