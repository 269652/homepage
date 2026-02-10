#!/bin/bash

# Wait for nginx to start
sleep 5

# Request certificates for both domains
certbot certonly --webroot -w /var/www/certbot \
    --email ${CERTBOT_EMAIL} \
    --agree-tos \
    --no-eff-email \
    -d ${FRONTEND_DOMAIN} \
    --non-interactive || true

certbot certonly --webroot -w /var/www/certbot \
    --email ${CERTBOT_EMAIL} \
    --agree-tos \
    --no-eff-email \
    -d ${BACKEND_DOMAIN} \
    --non-interactive || true

# Reload nginx to pick up new certificates
nginx -s reload
