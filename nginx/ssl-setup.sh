#!/bin/sh

# Create directories for Let's Encrypt
mkdir -p /etc/letsencrypt/live/javascript.moe
mkdir -p /etc/letsencrypt/live/strapi.javascript.moe

# Function to check if certificate exists and is valid
check_cert() {
    domain=$1
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ] && \
       [ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]; then
        if openssl x509 -checkend 2592000 -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" >/dev/null 2>&1; then
            echo "Certificate for $domain is still valid"
            return 0
        else
            echo "Certificate for $domain is expiring soon or expired"
            return 1
        fi
    else
        echo "Certificate for $domain does not exist"
        return 1
    fi
}

# Function to create self-signed certificate as fallback
create_self_signed() {
    domain=$1
    echo "Creating self-signed certificate for $domain as fallback..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "/etc/letsencrypt/live/$domain/privkey.pem" \
        -out "/etc/letsencrypt/live/$domain/fullchain.pem" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$domain"
}

# Obtain certificate for each domain separately
for domain in javascript.moe strapi.javascript.moe; do
    if ! check_cert "$domain"; then
        echo "=== Obtaining certificate for $domain using standalone mode ==="

        certbot certonly \
            --standalone \
            --preferred-challenges http \
            --email ${CERTBOT_EMAIL:-admin@javascript.moe} \
            --agree-tos \
            --no-eff-email \
            -d $domain

        if [ $? -eq 0 ]; then
            echo "Certificate obtained successfully for $domain"
        else
            echo "Certbot failed for $domain, creating self-signed fallback..."
            create_self_signed "$domain"
        fi
    fi
done

# Set up SSL nginx configs
echo "Setting up SSL nginx configurations..."
rm -f /etc/nginx/sites-enabled/*.conf
ln -sf /etc/nginx/sites-available/javascript.moe.conf /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/strapi.javascript.moe.conf /etc/nginx/sites-enabled/

# Start nginx in foreground
echo "Starting nginx..."
exec nginx -g 'daemon off;'
