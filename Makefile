build:
	cd docker/app_a/ && docker build --tag density:app_a .
	cd docker/app_b/ && docker build --tag density:app_b .

setup:
	minikube start
	eval $$(minikube docker-env)

deploy:
	kubectl apply -Rf kubernetes/
