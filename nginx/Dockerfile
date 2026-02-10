FROM nginx:alpine

# Install certbot and openssl
RUN apk add --no-cache certbot certbot-nginx openssl cronie

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create necessary directories
RUN mkdir -p /etc/nginx/sites-available \
    && mkdir -p /etc/nginx/sites-enabled \
    && mkdir -p /var/www/certbot \
    && mkdir -p /var/log/nginx

# Copy sites-available configs (symlinks created at runtime by init-nginx.sh)
COPY sites-available/ /etc/nginx/sites-available/

# Copy scripts
COPY init-nginx.sh /docker-entrypoint.d/01-init-nginx.sh
COPY ssl-setup.sh /usr/local/bin/ssl-setup.sh
COPY switch-to-ssl.sh /usr/local/bin/switch-to-ssl.sh

# Make scripts executable
RUN chmod +x /docker-entrypoint.d/01-init-nginx.sh \
    && chmod +x /usr/local/bin/ssl-setup.sh \
    && chmod +x /usr/local/bin/switch-to-ssl.sh

# Expose ports
EXPOSE 80 443

# Start SSL setup in background, then run nginx in foreground
CMD ["/bin/sh", "-c", "(/usr/local/bin/ssl-setup.sh && /usr/local/bin/switch-to-ssl.sh) & nginx -g 'daemon off;'"]
