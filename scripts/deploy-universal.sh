#!/bin/bash

# RYHA Ultra SearXNG - Quick Deploy Script for Any Kubernetes Cluster
# Works with: minikube, kind, existing clusters, Azure AKS, Google GKE, AWS EKS

set -e

echo "🚀 RYHA Ultra SearXNG - Universal Kubernetes Deployment"
echo "======================================================"

# Check if kubectl is installed and configured
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first:"
    echo "   https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please ensure:"
    echo "   - Your cluster is running"
    echo "   - kubectl is configured correctly"
    echo "   - You have proper permissions"
    exit 1
fi

echo "✅ kubectl connection verified"

# Show cluster info
echo "🔍 Cluster Information:"
kubectl cluster-info
echo ""

# Show current context
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📍 Current context: $CURRENT_CONTEXT"
echo ""

# Confirm deployment
read -p "🚀 Deploy RYHA Ultra SearXNG to this cluster? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo "🚀 Starting deployment..."

# Apply manifests in order
echo "📦 Creating namespace..."
kubectl apply -f kubernetes/01-namespace.yaml

echo "⚙️  Applying configuration..."
kubectl apply -f kubernetes/02-configmap.yaml

echo "🐳 Deploying application..."
kubectl apply -f kubernetes/03-deployment.yaml

echo "🌐 Creating service..."
kubectl apply -f kubernetes/04-service.yaml

echo "🔄 Setting up ingress (optional)..."
kubectl apply -f kubernetes/05-ingress.yaml || echo "⚠️  Ingress controller not available - skipping"

echo "🛡️  Applying pod disruption budget..."
kubectl apply -f kubernetes/06-pod-disruption-budget.yaml

echo "📊 Setting up auto-scaling..."
kubectl apply -f kubernetes/07-hpa.yaml || echo "⚠️  Metrics server not available - skipping HPA"

echo "✅ All manifests applied!"

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/ryha-searxng-deployment -n ryha-searxng

echo "✅ Deployment is ready!"

# Get pod status
echo "📊 Pod Status:"
kubectl get pods -n ryha-searxng -o wide

# Get service info
echo "🌐 Service Information:"
kubectl get service ryha-searxng-service -n ryha-searxng

# Check service type and provide access instructions
SERVICE_TYPE=$(kubectl get service ryha-searxng-service -n ryha-searxng -o jsonpath='{.spec.type}')

echo ""
echo "🎉 DEPLOYMENT COMPLETED!"
echo "======================"

if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
    EXTERNAL_IP=$(kubectl get service ryha-searxng-service -n ryha-searxng -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo "✅ LoadBalancer External IP: $EXTERNAL_IP"
        echo "🌐 Access URL: http://$EXTERNAL_IP"
    else
        echo "⏳ LoadBalancer IP is pending..."
        echo "   Run: kubectl get service ryha-searxng-service -n ryha-searxng --watch"
    fi
elif [ "$SERVICE_TYPE" = "NodePort" ]; then
    NODE_PORT=$(kubectl get service ryha-searxng-service -n ryha-searxng -o jsonpath='{.spec.ports[0].nodePort}')
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    echo "✅ NodePort Service"
    echo "🌐 Access URL: http://$NODE_IP:$NODE_PORT"
else
    echo "✅ ClusterIP Service (internal only)"
    echo "🔗 Use port-forward to access: kubectl port-forward service/ryha-searxng-service 8080:80 -n ryha-searxng"
    echo "   Then access: http://localhost:8080"
fi

echo ""
echo "🔍 Test your deployment:"
if [ "$SERVICE_TYPE" = "LoadBalancer" ] && [ ! -z "$EXTERNAL_IP" ]; then
    echo "   curl http://$EXTERNAL_IP/search?q=test&format=json"
elif [ "$SERVICE_TYPE" = "NodePort" ]; then
    echo "   curl http://$NODE_IP:$NODE_PORT/search?q=test&format=json"
else
    echo "   After port-forward: curl http://localhost:8080/search?q=test&format=json"
fi

echo ""
echo "🛠️  Management Commands:"
echo "  View logs:      kubectl logs -f deployment/ryha-searxng-deployment -n ryha-searxng"
echo "  Scale up:       kubectl scale deployment ryha-searxng-deployment --replicas=5 -n ryha-searxng"
echo "  Delete:         kubectl delete namespace ryha-searxng"
echo "  Update config:  kubectl edit configmap searxng-config -n ryha-searxng"

echo ""
echo "🚀 Your RYHA Ultra SearXNG is now running!"
echo "   Features: 40+ search engines, anti-captcha, ultra-fast performance"