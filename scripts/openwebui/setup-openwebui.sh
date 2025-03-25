#!/bin/bash
# Script to set up OpenWebUI connected to Ollama
# This script handles the deployment of OpenWebUI and configures it to connect to Ollama

set -e

echo "Setting up OpenWebUI with Mistral connection..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Create namespace if it doesn't exist
echo "Creating openwebui namespace if it doesn't exist..."
kubectl create namespace openwebui --dry-run=client -o yaml | kubectl apply -f -

# Apply deployment
echo "Deploying OpenWebUI..."
kubectl apply -f ../configs/openwebui/openwebui-deployment.yaml

# Create a service for OpenWebUI
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: openwebui-service
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
kubectl -n openwebui wait --for=condition=ready pod -l app=openwebui --timeout=300s

# Check if OpenWebUI is accessible
OPENWEBUI_POD=$(kubectl get pods -n openwebui -l app=openwebui -o jsonpath="{.items[0].metadata.name}")
if [ -n "$OPENWEBUI_POD" ]; then
    echo "OpenWebUI is running in pod: $OPENWEBUI_POD"
    echo "OpenWebUI is configured to connect to Ollama at: http://ollama-service.ollama.svc.cluster.local:11434"
    
    # Get service information
    EXTERNAL_IP=$(kubectl get svc -n openwebui openwebui-service -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    if [ -n "$EXTERNAL_IP" ]; then
        echo "OpenWebUI is accessible at: http://$EXTERNAL_IP:3001"
    else
        echo "Waiting for external IP assignment. You can check it later with:"
        echo "  kubectl get svc -n openwebui openwebui-service"
    fi
else
    echo "Failed to deploy OpenWebUI. Check the logs with:"
    echo "  kubectl -n openwebui logs -l app=openwebui"
fi

echo "Setup complete."
