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

# Check if any domain needs a certificate
needs_cert=false
for domain in javascript.moe strapi.javascript.moe; do
    if ! check_cert "$domain"; then
        needs_cert=true
        break
    fi
done

if [ "$needs_cert" = true ]; then
    echo "=== Obtaining certificates using standalone mode ==="
    echo "Certbot will start its own server on port 80..."

    certbot certonly \
        --standalone \
        --preferred-challenges http \
        --email ${CERTBOT_EMAIL:-admin@javascript.moe} \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -v \
        -d javascript.moe \
        -d strapi.javascript.moe

    if [ $? -eq 0 ]; then
        echo "Certificates obtained successfully!"
    else
        echo "Certbot failed, creating self-signed certificates as fallback..."
        for domain in javascript.moe strapi.javascript.moe; do
            create_self_signed "$domain"
        done
    fi
fi

# Now set up the SSL nginx configs
echo "Setting up SSL nginx configurations..."
rm -f /etc/nginx/sites-enabled/*.conf
ln -sf /etc/nginx/sites-available/javascript.moe.conf /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/strapi.javascript.moe.conf /etc/nginx/sites-enabled/

# Start nginx in foreground
echo "Starting nginx..."
exec nginx -g 'daemon off;'
