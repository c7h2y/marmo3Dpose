#!/usr/bin/env bash
set -e

proxy=$1
IMAGE_NAME="marmo:latest"

echo "=== 1. docker build ==="
sudo docker build --build-arg http_proxy="${proxy}"   --build-arg https_proxy="${proxy}" -t "${IMAGE_NAME}" .

echo "=== 2. docker run ==="
sudo docker run --rm -it --gpus all \
    -v /media/user/3a7895b8-6fc9-4b13-b3ed-2045ee637322/viddata:/app/marmo3Dpose/vid \
    -v ./work_dir:/app/marmo3Dpose/work \
    "${IMAGE_NAME}" bash
