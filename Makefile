build:
	cd docker/app_a/ && docker build --tag density:app_a .
	cd docker/app_b/ && docker build --tag density:app_b .
