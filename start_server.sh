#!/bin/bash
cd /home/bflsys34/Desktop/docuseal
while true; do
    echo "Starting DocuSeal server..."
    rails server -b 0.0.0.0 -p 3000
    echo "Server stopped, restarting in 5 seconds..."
    sleep 5
done

