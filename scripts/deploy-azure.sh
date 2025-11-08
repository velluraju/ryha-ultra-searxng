#!/bin/bash

# RYHA Ultra SearXNG - Quick Azure Deployment Script
# This script deploys RYHA Ultra SearXNG to Azure Kubernetes Service

set -e

echo "🚀 RYHA Ultra SearXNG - Azure Deployment Script"
echo "================================================="

# Configuration
RESOURCE_GROUP="ryha-searxng-production"
CLUSTER_NAME="ryha-searxng-aks"
LOCATION="centralindia"
NODE_COUNT=2
NODE_SIZE="Standard_B2s"

echo "📋 Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Location: $LOCATION"
echo "  Node Count: $NODE_COUNT"
echo "  Node Size: $NODE_SIZE"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first:"
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Installing..."
    az aks install-cli
fi

echo "✅ Prerequisites check passed"

# Login to Azure (if not already logged in)
if ! az account show &> /dev/null; then
    echo "🔐 Logging in to Azure..."
    az login
fi

echo "✅ Azure authentication verified"

# Create resource group if it doesn't exist
echo "📁 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION --output table

# Create AKS cluster if it doesn't exist
echo "☸️  Creating AKS cluster (this may take 10-15 minutes)..."
if ! az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME &> /dev/null; then
    az aks create \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --node-count $NODE_COUNT \
        --node-vm-size $NODE_SIZE \
        --enable-addons monitoring \
        --generate-ssh-keys \
        --output table
    echo "✅ AKS cluster created successfully!"
else
    echo "✅ AKS cluster already exists"
fi

# Get AKS credentials
echo "🔑 Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Verify cluster connection
echo "🔍 Verifying cluster connection..."
kubectl cluster-info

# Deploy RYHA Ultra SearXNG
echo "🚀 Deploying RYHA Ultra SearXNG..."

echo "  📦 Creating namespace..."
kubectl apply -f kubernetes/01-namespace.yaml

echo "  ⚙️  Applying configuration..."
kubectl apply -f kubernetes/02-configmap.yaml

echo "  🐳 Deploying application..."
kubectl apply -f kubernetes/03-deployment.yaml

echo "  🌐 Creating service..."
kubectl apply -f kubernetes/04-service.yaml

echo "  🔄 Setting up ingress..."
kubectl apply -f kubernetes/05-ingress.yaml

echo "  🛡️  Applying pod disruption budget..."
kubectl apply -f kubernetes/06-pod-disruption-budget.yaml

echo "  📊 Setting up auto-scaling..."
kubectl apply -f kubernetes/07-hpa.yaml

echo "✅ All resources deployed successfully!"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready (this may take 5-10 minutes)..."
kubectl wait --for=condition=available --timeout=600s deployment/ryha-searxng-deployment -n ryha-searxng

echo "✅ Deployment is ready!"

# Get service information
echo "🌐 Getting service information..."
kubectl get service ryha-searxng-service -n ryha-searxng -o wide

echo "⏳ Waiting for external IP assignment (this may take 3-5 minutes)..."
echo "   You can press Ctrl+C to stop waiting and check manually later"

# Wait for external IP with timeout
timeout 300 kubectl get service ryha-searxng-service -n ryha-searxng --watch || true

# Get final status
EXTERNAL_IP=$(kubectl get service ryha-searxng-service -n ryha-searxng -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo ""
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "====================================="

if [ ! -z "$EXTERNAL_IP" ]; then
    echo "✅ External IP: $EXTERNAL_IP"
    echo "🌐 Access URL: http://$EXTERNAL_IP"
    echo "🔍 Test URL: http://$EXTERNAL_IP/search?q=test&format=json"
else
    echo "⏳ External IP is still being allocated..."
    echo "   Run this command to check: kubectl get service ryha-searxng-service -n ryha-searxng"
fi

echo ""
echo "📊 Cluster Status:"
kubectl get pods -n ryha-searxng -o wide

echo ""
echo "🛠️  Useful Commands:"
echo "  Check pods:     kubectl get pods -n ryha-searxng"
echo "  Check service:  kubectl get service ryha-searxng-service -n ryha-searxng"
echo "  View logs:      kubectl logs -f deployment/ryha-searxng-deployment -n ryha-searxng"
echo "  Scale up:       kubectl scale deployment ryha-searxng-deployment --replicas=5 -n ryha-searxng"

echo ""
echo "🎯 Next Steps:"
echo "1. Wait for external IP allocation (may take up to 10 minutes)"
echo "2. Test your search engine at the provided URL"
echo "3. Integrate with your applications using the API endpoint"
echo "4. Monitor performance and scale as needed"

echo ""
echo "🚀 Your RYHA Ultra SearXNG is now running on Azure Kubernetes!"
echo "   Enjoy ultra-fast search with 40+ engines and anti-captcha technology!"