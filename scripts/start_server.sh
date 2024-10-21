#!/bin/bash
if [ "$(docker ps -q -f name=nextjs-container)" ]; then
    echo "Next.js container is running."
else
    echo "Next.js container failed to start."
    exit 1
fi