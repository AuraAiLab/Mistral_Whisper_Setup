#!/bin/bash
# Script to deploy OpenWebUI with persistent configuration using ConfigMaps and PVC
# This ensures settings are not lost or overwritten when making changes in OpenWebUI

set -e

echo "Deploying OpenWebUI with persistent configuration..."

# Create namespace if it doesn't exist
echo "Creating openwebui namespace if it doesn't exist..."
kubectl create namespace openwebui --dry-run=client -o yaml | kubectl apply -f -

# Apply PVC first
echo "Creating persistent volume claim for OpenWebUI data..."
kubectl apply -f ../configs/openwebui/openwebui-pvc.yaml

# Apply ConfigMap with settings
echo "Applying OpenWebUI configuration settings..."
kubectl apply -f ../configs/openwebui/openwebui-configmap.yaml

# Apply the deployment with references to PVC and ConfigMap
echo "Deploying OpenWebUI with persistent configuration..."
kubectl apply -f ../configs/openwebui/openwebui-deployment.yaml

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
kubectl -n openwebui wait --for=condition=ready pod -l app=openwebui --timeout=300s

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

echo "OpenWebUI deployment complete with persistent configuration!"
echo "Web search is enabled with DuckDuckGo as the default search engine."
echo "The configuration is stored in a ConfigMap and will not be overwritten by UI changes."
