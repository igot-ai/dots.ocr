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

# Debug: Check what files exist
echo "Contents of /app:"
ls -la /app/
echo "Contents of /app/docker (if exists):"
ls -la /app/docker/ || echo "No /app/docker directory"
echo "Looking for vllm_wrapper.py:"
find /app -name "vllm_wrapper.py" -type f || echo "vllm_wrapper.py not found anywhere"

# Run vLLM via our Python wrapper that pre-imports DotsOCR
exec python3 /usr/local/bin/vllm_wrapper.py "$@"