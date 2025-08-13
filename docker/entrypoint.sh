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

# Run vLLM via a lightweight Python wrapper that pre-imports DotsOCR
exec python3 - "$@" << 'PY'
import sys
import traceback

try:
    # Ensure DotsOCR is importable from PYTHONPATH
    from DotsOCR import modeling_dots_ocr_vllm  # noqa: F401
except Exception as exc:
    print("ERROR: Failed to import DotsOCR (check PYTHONPATH and mount path)", file=sys.stderr)
    traceback.print_exc()
    sys.exit(1)

from vllm.entrypoints.cli.main import main
# sys.argv will be ['-'] + original args; replace with a proper program name
sys.argv = ["vllm"] + sys.argv[1:]
main()
PY