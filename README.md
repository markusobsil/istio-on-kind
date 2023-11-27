# Istio testing environment automation based on KinD

## Background

I'm working with Istio on a day to day basic and need to test different
configurations. As it is very easy to spin up a Kubernetes cluster in seconds
with KinD, I created this Makefile to automated the creation of my Istio
testing environment.

## Prerequisites

I ran this on my MacBook only. It most probably will work on Linux too, but I
never tested it. To run it, you will need following tools:
* GNU make
* KinD
* kubectl
* helm

## What will be deployed with this Makefile
1. Create a new KinD Cluster
2. Deploy Istio controlplane (Istio Base and Istiod)
3. Deploy Istio ingress gateway, which is accessible via Port 8080 and 8443
4. Create a self-signed certificate for the ingress gateway
5. Deploy Istio egress gateway (optional)
6. Deploy a basic NGINX container and expose it via the ingress gateway (optional)
7. Deploy a curl container that constantly connects to the NGINX container (optional)
