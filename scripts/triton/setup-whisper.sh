#!/bin/bash
# Script to set up Whisper on Triton Inference Server
# This script handles the deployment of Triton and preparing Whisper model

set -e

echo "Setting up Whisper on Triton Inference Server..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Create directory structure for model repository
echo "Creating model repository directory structure..."
mkdir -p /models/triton/model_repo/whisper/{1,config}

# Copy config file
echo "Copying model configuration..."
cp ../configs/triton/whisper/config.pbtxt /models/triton/model_repo/whisper/config/

# Create namespace if it doesn't exist
echo "Creating triton-inference namespace if it doesn't exist..."
kubectl create namespace triton-inference --dry-run=client -o yaml | kubectl apply -f -

# Apply PV and PVC
echo "Creating persistent volume and claim for Triton..."
kubectl apply -f ../configs/triton/triton-pv.yaml
kubectl apply -f ../configs/triton/triton-pvc.yaml

# Check if we need to download and convert the Whisper model
if [ ! -f "/models/triton/model_repo/whisper/1/model.onnx" ]; then
    echo "Whisper model not found. Downloading and converting..."
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR
    
    # Install necessary packages
    pip install torch torchaudio transformers optimum onnx onnxruntime
    
    # Create a Python script to convert the model
    cat > convert_whisper.py << 'EOF'
import torch
from transformers import WhisperForConditionalGeneration, WhisperProcessor
from optimum.onnx import ORTModelForSpeechSeq2Seq, ORTOptimizer
from optimum.onnx.configuration import OptimizationConfig

# Load model and processor
model_id = "openai/whisper-base"
processor = WhisperProcessor.from_pretrained(model_id)
model = WhisperForConditionalGeneration.from_pretrained(model_id)

# Convert to ONNX
onnx_model = ORTModelForSpeechSeq2Seq.from_pretrained(model_id, export=True)

# Save the model
onnx_model.save_pretrained("/models/triton/model_repo/whisper/1")

# Also save the processor for later use
processor.save_pretrained("/models/triton/model_repo/whisper/1/processor")
EOF
    
    # Run the conversion script
    python convert_whisper.py
    
    # Clean up
    cd -
    rm -rf $TMP_DIR
    
    echo "Whisper model converted and saved to /models/triton/model_repo/whisper/1/"
else
    echo "Whisper model already exists at /models/triton/model_repo/whisper/1/"
fi

# Apply deployment and service
echo "Deploying Triton Inference Server..."
kubectl apply -f ../configs/triton/triton-deployment.yaml
kubectl apply -f ../configs/triton/triton-service.yaml

# Wait for Triton pod to be ready
echo "Waiting for Triton pod to be ready..."
kubectl -n triton-inference wait --for=condition=ready pod -l app=triton-inference-server --timeout=300s

# Set up port-forwarding in the background
echo "Setting up port-forwarding to access Triton..."
kubectl -n triton-inference port-forward svc/triton-inference-server 8000:8000 &
PORT_FORWARD_PID=$!

# Give port-forwarding a moment to establish
sleep 5

# Check if Triton is accessible
if curl -s http://localhost:8000/v2/health/ready > /dev/null; then
    echo "Triton Inference Server is accessible and ready."
    echo "Checking model status..."
    
    # Check model status
    curl -s http://localhost:8000/v2/models/whisper
    
    echo ""
    echo "Whisper model is set up on Triton and ready to use."
    echo "You can send inference requests to http://localhost:8000/v2/models/whisper/infer"
else
    echo "Failed to connect to Triton. Check the pod logs for issues:"
    kubectl -n triton-inference logs -l app=triton-inference-server
fi

# Clean up port-forwarding
kill $PORT_FORWARD_PID

echo "Setup complete."
