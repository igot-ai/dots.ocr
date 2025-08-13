#!/usr/bin/env python3
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

if __name__ == "__main__":
    main()