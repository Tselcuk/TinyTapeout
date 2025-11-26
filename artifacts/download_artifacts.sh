#!/bin/bash

# Script to download artifacts from a GitHub Actions run
# Usage: ./download_artifacts.sh <run_id>
# Example: ./download_artifacts.sh 19111708384

if [ $# -eq 0 ]; then
    echo "Error: Run ID is required"
    echo "Usage: $0 <run_id>"
    echo "Example: $0 19111708384"
    exit 1
fi

RUN_ID=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACTS_DIR="$SCRIPT_DIR"

echo "Downloading artifacts from run $RUN_ID..."
echo "Artifacts will be saved to: $ARTIFACTS_DIR"

cd "$SCRIPT_DIR/.." || exit 1

if gh run download "$RUN_ID" --dir "$ARTIFACTS_DIR"; then
    echo "✓ Successfully downloaded artifacts to $ARTIFACTS_DIR"
else
    echo "✗ Failed to download artifacts"
    exit 1
fi

