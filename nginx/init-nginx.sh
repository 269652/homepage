#!/bin/sh

# Create necessary directories
mkdir -p /etc/nginx/sites-enabled
mkdir -p /var/www/certbot

# Clean any stale configs - ssl-setup.sh will set up the right ones
rm -f /etc/nginx/sites-enabled/*.conf

echo "Nginx initialization completed!"
