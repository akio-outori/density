# Kubernetes Application Scaling

## Overview

Deploy a simple stateless application to a kubernetes cluster designed to scale based on number of requests.

## Requirements

* Deploy the sample python application to kubernetes.
* Only the frontend container (app_a) should be publicly available.
* Scale the number of pods and number of nodes based on request volume.
* Plan for Continuous Delivery to a production environment.

## Design

In order to accomplish these goals I created two environments in code:

* **Local Dev** - Minikube single node based on virtualbox.
* **Dev/Test** - AWS EKS cluster implementing autoscaling across multiple Availability Zones fronted by an Elastic Load Balancer.

The production environment could be very similar (if not identical) to the Dev/Test environment, and in general I try to keep 
Pre-prod and prod as close as possible.

Scaling based on requests is implemented using three kubernetes components:

* **Horizontal Pod Autoscaler** - Built in functionality to scale pods up and down based on various metrics (cpu/mem supported by default).
* **Prometheus / Prometheus Adapter** - Add-on component used to expose custom application metrics via the kubernetes API.
* **Horizontal Node Autoscaler** - Add-on component to allow kubernetes to adjust the number of nodes in an autoscaling group based on capacity.

## Continuous Delivery

While not implemented here, Continuous Delivery could be added via a platform like Jenkins, and a skeleton for a Jenkinsfile and basic jenkins
deployment definition is included.  The file contains definitions for build, local, dev, and prod deployment options.  

Depending on how much of the underlying infrastructure needed to be tested at each phase, the stages could be something like:

1. **Build** - Build docker containers from the source code or fail.

2. **Local** - Spin up a local minikube cluster to test kubernetes deployment.
   Test for:
     * Successful `kubectl apply -Rf kubernetes/density` deployment (command exited successfully).
     * http://app/hello is reachable on the local network.
     * https://app/jobs returns the correct output on a PUT request.

3. **Dev/Test** - Deploy to a Dev kubernetes environment in AWS.  All that should be needed to do this is
   to change the target cluster using `kubectl config use-context`.
   Test all of the above plus:
     * Test for successful pod scaling by queueing a number of requests.
         * Check that custom metrics are reporting correctly (get values from the `/apis/custom.metrics.k8s.io/v1beta1` endpoint)
         * Check for number of pods in the replicaset for the application.
     * Test for successful node scale up / scale down 
         * Check for events via the `/apis/events.k8s.io/v1beta1` endpoint, look for cluster scaling events.
     * Test application response time at scale.
         * During load testing, check application average response time either via the `/apis/custom.metrics.k8s.io/v1beta1` endpoint or via a tooling suite

4. **Prod** - Deploy to a Prod kubernetes environment in AWS.  Test for:
   * Successful `kubectl apply -Rf kubernetes/density` deployment (command exited successfully).
   * URLs are reachable and return the expected content.
   * Response time and average load stabilize after deployment.
   * If applicable, also test if pods are well distributed across AZs and Regions.
