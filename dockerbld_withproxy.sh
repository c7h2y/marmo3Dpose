#!/usr/bin/env bash

proxy=$1
IMAGE_NAME="marmo:test"

echo "=== 1. docker build ==="
docker build --build-arg http_proxy="${proxy}"   --build-arg https_proxy="${proxy}" -t "${IMAGE_NAME}" .

echo "=== 2. docker run ==="
docker run --rm -it --gpus all -v /media/user/3a7895b8-6fc9-4b13-b3ed-2045ee637322/viddata:/app/vid "${IMAGE_NAME}" bash
