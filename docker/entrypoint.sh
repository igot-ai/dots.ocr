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

echo "DotsOCR model found, registering with vLLM..."
# Register DotsOCR model with vLLM if not already done
VLLM_SCRIPT=$(which vllm)

if ! grep -q "from DotsOCR import modeling_dots_ocr_vllm" "$VLLM_SCRIPT"; then
    echo "Registering DotsOCR with vLLM..."
    sudo sed -i "/^from vllm\.entrypoints\.cli\.main import main$/a\\
from DotsOCR import modeling_dots_ocr_vllm" "$VLLM_SCRIPT"
    echo "DotsOCR registered with vLLM successfully"
else
    echo "DotsOCR already registered with vLLM"
fi

# Launch vLLM server with provided arguments
echo "Launching vLLM server..."
exec vllm "$@"