#!/bin/sh

# Wait for SSL certificates to be ready
while [ ! -f /etc/letsencrypt/live/javascript.moe/fullchain.pem ] || [ ! -f /etc/letsencrypt/live/strapi.javascript.moe/fullchain.pem ]; do
    echo "Waiting for SSL certificates..."
    sleep 5
done

echo "SSL certificates found, switching to SSL configurations..."

# Remove HTTP-only configurations
rm -f /etc/nginx/sites-enabled/*.conf

# Link the SSL configurations
ln -sf /etc/nginx/sites-available/javascript.moe.conf /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/strapi.javascript.moe.conf /etc/nginx/sites-enabled/

# Test nginx configuration
if nginx -t; then
    echo "Nginx configuration is valid, reloading..."
    nginx -s reload
    echo "SSL configuration activated!"
else
    echo "Nginx configuration test failed!"
    exit 1
fi