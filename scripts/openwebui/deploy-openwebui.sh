#!/bin/bash
# Script to deploy OpenWebUI with persistent configuration using ConfigMaps
# This ensures settings are not lost or overwritten when making changes in OpenWebUI

set -e

# Get the project root directory
PROJECT_ROOT=$(pwd)

echo "Deploying OpenWebUI with persistent configuration..."

# Create namespace if it doesn't exist
echo "Creating openwebui namespace if it doesn't exist..."
kubectl create namespace openwebui --dry-run=client -o yaml | kubectl apply -f -

# Get Ollama service IP for host aliases
echo "Getting Ollama service IP for host aliases configuration..."
OLLAMA_SERVICE_IP=$(kubectl get service -n ollama ollama-service -o jsonpath='{.spec.clusterIP}')
if [ -z "$OLLAMA_SERVICE_IP" ]; then
    echo "Error: Could not get Ollama service IP. Make sure the Ollama service is running."
    exit 1
fi
echo "Found Ollama service IP: $OLLAMA_SERVICE_IP"

# Apply ConfigMap with settings
echo "Applying OpenWebUI configuration settings..."
kubectl apply -f ${PROJECT_ROOT}/configs/openwebui/openwebui-configmap.yaml

# Create a temporary deployment file with the correct host aliases
echo "Creating deployment with host aliases pointing to Ollama service..."
TMP_DEPLOYMENT="/tmp/openwebui-deployment-$$.yaml"
cp ${PROJECT_ROOT}/configs/openwebui/openwebui-deployment.yaml $TMP_DEPLOYMENT

# Update the host aliases in the temporary deployment file
sed -i "s/ip: \"10.104.100.227\"/ip: \"$OLLAMA_SERVICE_IP\"/g" $TMP_DEPLOYMENT

# Apply the deployment with references to ConfigMap and host aliases
echo "Deploying OpenWebUI with persistent configuration and host aliases..."
kubectl apply -f $TMP_DEPLOYMENT

# Create a service for OpenWebUI if it doesn't exist
echo "Creating service for OpenWebUI..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: openwebui
  namespace: openwebui
spec:
  selector:
    app: openwebui
  ports:
  - port: 3001
    targetPort: 3000
  type: LoadBalancer
EOF

# Wait for OpenWebUI pod to be ready
echo "Waiting for OpenWebUI pod to be ready..."
kubectl -n openwebui wait --for=condition=ready pod -l app=openwebui --timeout=120s

# Check if OpenWebUI is accessible
OPENWEBUI_POD=$(kubectl get pods -n openwebui -l app=openwebui -o jsonpath="{.items[0].metadata.name}")
if [ -n "$OPENWEBUI_POD" ]; then
    echo "OpenWebUI is running in pod: $OPENWEBUI_POD"
    echo "OpenWebUI is configured to connect to Ollama at: http://ollama-service.ollama.svc.cluster.local:11434"
    
    # Get external IP for accessing OpenWebUI
    EXTERNAL_IP=$(kubectl get svc -n openwebui openwebui -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    if [ -n "$EXTERNAL_IP" ]; then
        echo "OpenWebUI is accessible at: http://$EXTERNAL_IP:3001"
    else
        echo "External IP not yet assigned. Check the service status with:"
        echo "  kubectl get svc -n openwebui openwebui"
    fi
else
    echo "Failed to deploy OpenWebUI. Check the logs with:"
    echo "  kubectl -n openwebui logs -l app=openwebui"
fi

# Clean up the temporary deployment file
rm -f $TMP_DEPLOYMENT

echo "OpenWebUI deployment complete with persistent configuration!"
echo "Web search is enabled with DuckDuckGo as the default search engine."
echo "The configuration is stored in a ConfigMap with host aliases to ensure connectivity to Ollama."
echo "Mistral 7B model should now be visible in the OpenWebUI interface."
