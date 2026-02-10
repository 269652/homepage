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

    # Create temporary HTTP-only config for javascript.moe
    cat > /etc/nginx/sites-enabled/javascript.moe.conf << 'EOF'
server {
    listen 80;
    server_name javascript.moe;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://nextjs:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Create temporary HTTP-only config for strapi.javascript.moe
    cat > /etc/nginx/sites-enabled/strapi.javascript.moe.conf << 'EOF'
server {
    listen 80;
    server_name strapi.javascript.moe;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://strapi:1337;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 100M;
    }
}
EOF
fi

# Create webroot directory for certbot
mkdir -p /var/www/certbot

echo "Nginx initialization completed!"
