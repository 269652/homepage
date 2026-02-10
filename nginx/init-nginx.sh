#!/bin/sh

# Create sites-enabled directory
mkdir -p /etc/nginx/sites-enabled

# Remove any existing symlinks
rm -f /etc/nginx/sites-enabled/*.conf

# Check if SSL certificates exist
if [ -f "/etc/letsencrypt/live/javascript.moe/fullchain.pem" ] && \
   [ -f "/etc/letsencrypt/live/strapi.javascript.moe/fullchain.pem" ]; then
    echo "SSL certificates found, enabling HTTPS configs..."
    ln -sf /etc/nginx/sites-available/javascript.moe.conf /etc/nginx/sites-enabled/
    ln -sf /etc/nginx/sites-available/strapi.javascript.moe.conf /etc/nginx/sites-enabled/
else
    echo "SSL certificates not found, creating HTTP-only configs for initial setup..."

    # Create temporary HTTP-only config for certbot validation
    # Only serve ACME challenges - proxy to upstreams only after certs are obtained
    cat > /etc/nginx/sites-enabled/javascript.moe.conf << 'EOF'
server {
    listen 80;
    server_name javascript.moe;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    location / {
        return 503 "Service temporarily unavailable - obtaining SSL certificate";
    }
}
EOF

    cat > /etc/nginx/sites-enabled/strapi.javascript.moe.conf << 'EOF'
server {
    listen 80;
    server_name strapi.javascript.moe;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    location / {
        return 503 "Service temporarily unavailable - obtaining SSL certificate";
    }
}
EOF
fi

# Create webroot directory for certbot
mkdir -p /var/www/certbot

echo "Nginx initialization completed!"
