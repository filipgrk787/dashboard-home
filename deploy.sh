#!/bin/bash

cd /home/filipgrk/filipgrk-project || exit

echo "🔄 Pulling latest changes from GitHub..."
git pull origin main

echo "🔁 Restarting the Flask dashboard service..."
sudo systemctl restart ping-dashboard.service

echo "✅ Deployment complete."
