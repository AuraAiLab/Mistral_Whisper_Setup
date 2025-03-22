#!/bin/bash
# Script to set up Mistral 7B on Ollama
# This script handles the deployment of Ollama and pulling the Mistral 7B model

set -e

echo "Setting up Mistral 7B on Ollama..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Create namespace if it doesn't exist
echo "Creating ollama namespace if it doesn't exist..."
kubectl create namespace ollama --dry-run=client -o yaml | kubectl apply -f -

# Apply PV and PVC
echo "Creating persistent volume and claim for Ollama..."
kubectl apply -f ../configs/ollama/ollama-pv.yaml
kubectl apply -f ../configs/ollama/ollama-pvc.yaml

# Apply deployment and service
echo "Deploying Ollama..."
kubectl apply -f ../configs/ollama/ollama-deployment.yaml
kubectl apply -f ../configs/ollama/ollama-service.yaml

# Wait for Ollama pod to be ready
echo "Waiting for Ollama pod to be ready..."
kubectl -n ollama wait --for=condition=ready pod -l app=ollama --timeout=300s

# Set up port-forwarding in the background
echo "Setting up port-forwarding to access Ollama..."
kubectl -n ollama port-forward svc/ollama-service 11434:11434 &
PORT_FORWARD_PID=$!

# Give port-forwarding a moment to establish
sleep 5

# Check if Ollama is accessible
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "Ollama is accessible. Pulling Mistral 7B model..."
    
    # Pull Mistral 7B model
    curl -X POST http://localhost:11434/api/pull -d '{"name": "mistral:7b"}'
    
    echo "Mistral 7B model pulled successfully."
    echo "Testing the model with a simple prompt..."
    
    # Test the model with a simple prompt
    curl -X POST http://localhost:11434/api/generate -d '{
        "model": "mistral:7b",
        "prompt": "Hello, I am an AI assistant.",
        "stream": false
    }'
    
    echo ""
    echo "Mistral 7B is set up and ready to use."
    echo "You can interact with it using the Ollama API at http://localhost:11434/api/generate"
else
    echo "Failed to connect to Ollama. Check the pod logs for issues:"
    kubectl -n ollama logs -l app=ollama
fi

# Clean up port-forwarding
kill $PORT_FORWARD_PID

echo "Setup complete."
