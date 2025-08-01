#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying Basic Healthcare App to AKS${NC}"

# Check if required tools are installed
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is required but not installed.${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v az >/dev/null 2>&1 || { echo -e "${RED}❌ Azure CLI is required but not installed.${NC}" >&2; exit 1; }

# Configuration
RESOURCE_GROUP="rg-dev-v2-EastUS"
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv 2>/dev/null || echo "")
AKS_NAME=$(az aks list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv 2>/dev/null || echo "")

if [ -z "$ACR_NAME" ] || [ -z "$AKS_NAME" ]; then
    echo -e "${RED}❌ Could not find ACR or AKS in resource group $RESOURCE_GROUP${NC}"
    echo -e "${YELLOW}Please run terraform apply first to create the infrastructure${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found ACR: $ACR_NAME${NC}"
echo -e "${GREEN}✅ Found AKS: $AKS_NAME${NC}"

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" -o tsv)
IMAGE_NAME="$ACR_LOGIN_SERVER/basic-healthcare:latest"

echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t $IMAGE_NAME .

echo -e "${YELLOW}🔐 Logging into ACR...${NC}"
az acr login --name $ACR_NAME

echo -e "${YELLOW}📤 Pushing image to ACR...${NC}"
docker push $IMAGE_NAME

echo -e "${YELLOW}🔗 Getting AKS credentials...${NC}"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

echo -e "${YELLOW}📝 Updating Kubernetes manifests...${NC}"
# Update the deployment YAML with the correct image name
sed "s|REGISTRY_NAME.azurecr.io/basic-healthcare:latest|$IMAGE_NAME|g" k8s/deployment.yaml > k8s/deployment-updated.yaml

echo -e "${YELLOW}🚀 Deploying to AKS...${NC}"
kubectl apply -f k8s/deployment-updated.yaml
kubectl apply -f k8s/service.yaml

echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/basic-healthcare-app --timeout=300s

echo -e "${GREEN}✅ Deployment complete!${NC}"

echo -e "${YELLOW}📊 Getting service information...${NC}"
kubectl get services basic-healthcare-service

echo -e "${GREEN}🎉 Your app is deployed! Use the following to check status:${NC}"
echo "kubectl get pods"
echo "kubectl get services"
echo ""
echo -e "${GREEN}To get the external IP address:${NC}"
echo "kubectl get service basic-healthcare-service"

# Clean up temporary file
rm -f k8s/deployment-updated.yaml
