#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Navigate to the application directory
cd /opt/app

# Start Prometheus Node Exporter in the background and redirect logs
prometheus-node-exporter --web.listen-address=:9100  --no-collector.systemd > /var/log/node_exporter.log 2>&1 &

# Start the Python application and redirect logs
python server.py > /var/log/server.log 2>&1