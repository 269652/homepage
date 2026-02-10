#!/bin/sh

# Wait for nginx to be ready
echo "Waiting for nginx to be ready..."
sleep 5

# Verify ACME challenge path is working
mkdir -p /var/www/certbot/.well-known/acme-challenge
echo "test" > /var/www/certbot/.well-known/acme-challenge/test-file
if wget -q -O - http://localhost/.well-known/acme-challenge/test-file 2>/dev/null | grep -q "test"; then
    echo "ACME challenge path is working correctly"
else
    echo "WARNING: ACME challenge path is NOT working"
fi
rm -f /var/www/certbot/.well-known/acme-challenge/test-file

# Create directories for Let's Encrypt
mkdir -p /etc/letsencrypt/live/javascript.moe
mkdir -p /etc/letsencrypt/live/strapi.javascript.moe

# Function to check if certificate exists and is valid
check_cert() {
    domain=$1
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        # Check if certificate is still valid (more than 30 days left)
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
    echo "Obtaining certificates for all domains in a single request..."

    certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email ${CERTBOT_EMAIL:-admin@javascript.moe} \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d javascript.moe \
        -d strapi.javascript.moe

    if [ $? -eq 0 ]; then
        echo "Certificates obtained successfully"
    else
        echo "Certbot failed, creating self-signed certificates as fallback..."
        for domain in javascript.moe strapi.javascript.moe; do
            create_self_signed "$domain"
        done
    fi
fi

# Reload nginx to use new certificates
echo "Reloading nginx..."
nginx -s reload

# Set up automatic renewal
echo "Setting up automatic certificate renewal..."
echo "0 12 * * * /usr/bin/certbot renew --quiet && nginx -s reload" > /etc/cron.d/certbot-renew
chmod 0644 /etc/cron.d/certbot-renew

echo "SSL setup completed!"
