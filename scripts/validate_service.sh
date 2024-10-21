#!/bin/bash

# Retrieve the public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Retrieved Public IP: $PUBLIC_IP"

# Check if the public IP was retrieved successfully
if [ -z "$PUBLIC_IP" ]; then
  echo "Failed to retrieve public IP."
  exit 1
fi

# Wait for a few seconds to allow the application to fully initialize
echo "Waiting for the application to initialize..."
sleep 10  # Delay for 10 seconds (adjust as needed)

# Check if the application is running by accessing the public IP
response=$(curl -I --connect-timeout 5 http://$PUBLIC_IP)

if [ $? -ne 0 ]; then
  echo "Application validation failed."
  echo "Response: $response"
  exit 1
else
  echo "Application is up and running."
  echo "Response: $response"
fi