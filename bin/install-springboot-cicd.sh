#!/usr/bin/env bash
# Create namespace used by the application

kubectl create namespace hello-world
kubectl label ns hello-world istio-injection=enabled
#The below is no longer needed with Istio 1.5 that comes in Konvoy 1.5 beta 7 and beyond
#kubectl label ns hello-world ca.istio.io/override="true"

# Install Dispatch on the cluster

# Do not install if `dispatch` namespace exists
kubectl get ns dispatch
if [ $? -eq 1 ]; then
    dispatch init --set global.prometheus.enabled=true --set global.prometheus.release=prometheus-kubeaddons --watch-namespace=dispatch
fi

# Create credentials for Dispatch

kubectl -n dispatch get serviceaccount dispatch-sa
if [ $? -eq 1 ]; then
    dispatch serviceaccount create dispatch-sa --namespace dispatch
fi
kubectl -n dispatch get secret dispatch-sa-basic-auth
if [ $? -eq 1 ]; then
    dispatch login github --user ${GITHUB_USERNAME} --token ${GITHUB_TOKEN} --service-account dispatch-sa --namespace dispatch
fi
docker login
kubectl -n dispatch get secret dispatch-sa-docker-auth
if [ $? -eq 1 ]; then
    dispatch login docker --service-account dispatch-sa --namespace dispatch
fi
#dispatch gitops creds add https://github.com/${GITHUB_USERNAME}/springboot-helloworld-dispatch --username=${GITHUB_USERNAME} --token=${GITHUB_TOKEN} --namespace dispatch

# Create CI Repository
#     This step creates the webhook in the Developers GitHub repository
#     This may also be done in the Dispatch UI!

dispatch ci repository create --service-account dispatch-sa --namespace dispatch --dispatchfile-path Dispatchfile.starlark

# Create the App for CD

dispatch gitops app create springboot-helloworld-dispatch \
         --repository=https://github.com/${GITHUB_USERNAME}/springboot-helloworld-dispatch-gitops \
         --service-account dispatch-sa \
         --namespace dispatch

# Bring up the application in a web browser

echo http://$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')/
