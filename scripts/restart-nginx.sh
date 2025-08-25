#!/bin/bash

# Script to restart Nginx with our custom configuration
echo "Stopping Nginx..."
sudo nginx -s stop

echo "Starting Nginx with custom configuration..."
sudo nginx -c $(pwd)/config/nginx.conf

echo "Nginx restarted successfully"
echo "To test: curl http://localhost:80/health" 