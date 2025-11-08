# Quick Deployment Guide

## 🚀 **Fastest Deployment Methods**

### **1. Azure Cloud Shell (Recommended)**
```bash
git clone https://github.com/velluraju/ryha-ultra-searxng.git
cd ryha-ultra-searxng
chmod +x scripts/deploy-azure.sh
./scripts/deploy-azure.sh
```

### **2. Local kubectl**
```bash
git clone https://github.com/velluraju/ryha-ultra-searxng.git
cd ryha-ultra-searxng
chmod +x scripts/deploy-universal.sh
./scripts/deploy-universal.sh
```

### **3. Manual kubectl**
```bash
kubectl apply -f kubernetes/
```

### **4. GitHub Actions (Automated)**
1. Fork this repository
2. Set up Azure Service Principal
3. Add GitHub secrets
4. Push to main branch

## 🎯 **What You Get**

- **40+ Search Engines** with anti-captcha technology
- **Sub-1 second response times** for most queries
- **High availability** with 3 replicas and auto-scaling
- **Enterprise-grade** Kubernetes deployment
- **Global accessibility** with load balancing

## 📊 **Expected Costs**

- **Azure AKS**: ~$60-75/month
- **Other clouds**: Similar pricing
- **Local cluster**: Free (if you have hardware)

## 🛠️ **Troubleshooting**

### **Common Issues:**
1. **kubectl not found**: Install kubectl
2. **Cluster connection failed**: Check kubeconfig
3. **Pods not starting**: Check resource limits
4. **No external IP**: Wait 5-10 minutes for Azure load balancer

### **Quick Checks:**
```bash
# Check pods
kubectl get pods -n ryha-searxng

# Check service
kubectl get service ryha-searxng-service -n ryha-searxng

# Check logs
kubectl logs deployment/ryha-searxng-deployment -n ryha-searxng
```

## 🔗 **Access Your Deployment**

Once deployed, you'll get an external IP:
- **Web Interface**: `http://YOUR-EXTERNAL-IP`
- **JSON API**: `http://YOUR-EXTERNAL-IP/search?q=test&format=json`

## 🎉 **Success!**

Your ultra-fast SearXNG is now running with:
- **0.5-2 second response times**
- **40+ search engines**
- **Advanced anti-captcha**
- **Enterprise reliability**