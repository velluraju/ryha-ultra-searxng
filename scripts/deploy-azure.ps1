# RYHA Ultra SearXNG - Windows PowerShell Deployment Script
# This script deploys RYHA Ultra SearXNG to Azure Kubernetes Service

param(
    [string]$ResourceGroup = "ryha-searxng-production",
    [string]$ClusterName = "ryha-searxng-aks",
    [string]$Location = "centralindia",
    [int]$NodeCount = 2,
    [string]$NodeSize = "Standard_B2s"
)

Write-Host "🚀 RYHA Ultra SearXNG - Azure Deployment Script" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "  Cluster Name: $ClusterName" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  Node Count: $NodeCount" -ForegroundColor White
Write-Host "  Node Size: $NodeSize" -ForegroundColor White
Write-Host ""

# Check if Azure CLI is installed
try {
    az --version | Out-Null
    Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if kubectl is installed
try {
    kubectl version --client | Out-Null
    Write-Host "✅ kubectl is installed" -ForegroundColor Green
} catch {
    Write-Host "📥 Installing kubectl..." -ForegroundColor Yellow
    az aks install-cli
}

# Login to Azure if not already logged in
try {
    az account show | Out-Null
    Write-Host "✅ Azure authentication verified" -ForegroundColor Green
} catch {
    Write-Host "🔐 Logging in to Azure..." -ForegroundColor Yellow
    az login
}

# Create resource group
Write-Host "📁 Creating resource group..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output table

# Check if AKS cluster exists
$clusterExists = $false
try {
    az aks show --resource-group $ResourceGroup --name $ClusterName | Out-Null
    $clusterExists = $true
    Write-Host "✅ AKS cluster already exists" -ForegroundColor Green
} catch {
    $clusterExists = $false
}

# Create AKS cluster if it doesn't exist
if (-not $clusterExists) {
    Write-Host "☸️  Creating AKS cluster (this may take 10-15 minutes)..." -ForegroundColor Yellow
    az aks create `
        --resource-group $ResourceGroup `
        --name $ClusterName `
        --node-count $NodeCount `
        --node-vm-size $NodeSize `
        --enable-addons monitoring `
        --generate-ssh-keys `
        --output table
    Write-Host "✅ AKS cluster created successfully!" -ForegroundColor Green
}

# Get AKS credentials
Write-Host "🔑 Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing

# Verify cluster connection
Write-Host "🔍 Verifying cluster connection..." -ForegroundColor Yellow
kubectl cluster-info

# Deploy RYHA Ultra SearXNG
Write-Host "🚀 Deploying RYHA Ultra SearXNG..." -ForegroundColor Green

Write-Host "  📦 Creating namespace..." -ForegroundColor White
kubectl apply -f kubernetes/01-namespace.yaml

Write-Host "  ⚙️  Applying configuration..." -ForegroundColor White
kubectl apply -f kubernetes/02-configmap.yaml

Write-Host "  🐳 Deploying application..." -ForegroundColor White
kubectl apply -f kubernetes/03-deployment.yaml

Write-Host "  🌐 Creating service..." -ForegroundColor White
kubectl apply -f kubernetes/04-service.yaml

Write-Host "  🔄 Setting up ingress..." -ForegroundColor White
kubectl apply -f kubernetes/05-ingress.yaml

Write-Host "  🛡️  Applying pod disruption budget..." -ForegroundColor White
kubectl apply -f kubernetes/06-pod-disruption-budget.yaml

Write-Host "  📊 Setting up auto-scaling..." -ForegroundColor White
kubectl apply -f kubernetes/07-hpa.yaml

Write-Host "✅ All resources deployed successfully!" -ForegroundColor Green

# Wait for deployment to be ready
Write-Host "⏳ Waiting for deployment to be ready (this may take 5-10 minutes)..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=600s deployment/ryha-searxng-deployment -n ryha-searxng

Write-Host "✅ Deployment is ready!" -ForegroundColor Green

# Get service information
Write-Host "🌐 Getting service information..." -ForegroundColor Yellow
kubectl get service ryha-searxng-service -n ryha-searxng -o wide

Write-Host "⏳ Waiting for external IP assignment..." -ForegroundColor Yellow
Write-Host "   (This may take 3-5 minutes)" -ForegroundColor Gray

# Wait for external IP
$maxAttempts = 60
$attempt = 0
$externalIP = ""

while ($attempt -lt $maxAttempts -and $externalIP -eq "") {
    Start-Sleep 5
    $attempt++
    try {
        $externalIP = kubectl get service ryha-searxng-service -n ryha-searxng -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        if ($externalIP -ne "") {
            break
        }
    } catch {
        # Continue waiting
    }
    
    if ($attempt -eq 1 -or $attempt % 6 -eq 0) {
        Write-Host "   Attempt $attempt/$maxAttempts - still waiting..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

if ($externalIP -ne "") {
    Write-Host "✅ External IP: $externalIP" -ForegroundColor Green
    Write-Host "🌐 Access URL: http://$externalIP" -ForegroundColor Cyan
    Write-Host "🔍 Test URL: http://$externalIP/search?q=test&format=json" -ForegroundColor Cyan
} else {
    Write-Host "⏳ External IP is still being allocated..." -ForegroundColor Yellow
    Write-Host "   Run this command to check: kubectl get service ryha-searxng-service -n ryha-searxng" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📊 Cluster Status:" -ForegroundColor Cyan
kubectl get pods -n ryha-searxng -o wide

Write-Host ""
Write-Host "🛠️  Useful Commands:" -ForegroundColor Cyan
Write-Host "  Check pods:     kubectl get pods -n ryha-searxng" -ForegroundColor White
Write-Host "  Check service:  kubectl get service ryha-searxng-service -n ryha-searxng" -ForegroundColor White
Write-Host "  View logs:      kubectl logs -f deployment/ryha-searxng-deployment -n ryha-searxng" -ForegroundColor White
Write-Host "  Scale up:       kubectl scale deployment ryha-searxng-deployment --replicas=5 -n ryha-searxng" -ForegroundColor White

Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Wait for external IP allocation (may take up to 10 minutes)" -ForegroundColor White
Write-Host "2. Test your search engine at the provided URL" -ForegroundColor White
Write-Host "3. Integrate with your applications using the API endpoint" -ForegroundColor White
Write-Host "4. Monitor performance and scale as needed" -ForegroundColor White

Write-Host ""
Write-Host "🚀 Your RYHA Ultra SearXNG is now running on Azure Kubernetes!" -ForegroundColor Green
Write-Host "   Enjoy ultra-fast search with 40+ engines and anti-captcha technology!" -ForegroundColor Green