#!/usr/bin/env bash

IMAGE_NAME="marmo:test"

echo "=== 1. docker build ==="
sudo docker build -t "${IMAGE_NAME}" .

echo "=== 2. docker run ==="
sudo docker run --rm -it --gpus all \
    -v /media/user/3a7895b8-6fc9-4b13-b3ed-2045ee637322/viddata:/app/vid \
    -v ./work_dir:/app/work \
    "${IMAGE_NAME}" bash