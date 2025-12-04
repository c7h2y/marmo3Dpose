#!/usr/bin/env bash
set -e

proxy=$1
mount=$2
IMAGE_NAME="marmo:latest"

echo "=== 1. docker build ==="
sudo docker build -t "${IMAGE_NAME}" .

echo "=== 2. docker run ==="
sudo docker run --rm -it --gpus all \
    -v ${mount}:/app/marmo3Dpose/vid \
    -v ./work_dir:/app/work \
    "${IMAGE_NAME}" bash