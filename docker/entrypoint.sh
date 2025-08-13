#!/bin/bash
set -e

echo "Starting DotsOCR vLLM server..."
echo "PYTHONPATH: $PYTHONPATH"
echo "hf_model_path: $hf_model_path"

# Check if DotsOCR model is mounted
if [ ! -d "/app/model/weights/DotsOCR" ]; then
    echo "ERROR: DotsOCR model directory not found at /app/model/weights/DotsOCR"
    echo "Please ensure the model is properly mounted via K8s storage"
    exit 1
fi

echo "Preloading DotsOCR and launching vLLM..."

# Run vLLM via our Python wrapper that pre-imports DotsOCR
exec python3 /app/docker/vllm_wrapper.py "$@"