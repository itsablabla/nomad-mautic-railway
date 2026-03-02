FROM mautic/mautic:5.2-apache

# Fix Apache MPM conflict - disable mpm_event and mpm_worker, enable only mpm_prefork
RUN a2dismod mpm_event mpm_worker 2>/dev/null || true && \
    a2enmod mpm_prefork && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2enmod expires

# Ensure PHP is enabled
RUN a2enmod php8.1 2>/dev/null || a2enmod php8.2 2>/dev/null || a2enmod php8.0 2>/dev/null || true

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Create a startup wrapper that configures Apache to listen on Railway's dynamic $PORT
RUN printf '#!/bin/bash\nPORT=${PORT:-80}\necho "Starting Apache on port $PORT"\nsed -i "s/Listen 80/Listen $PORT/g" /etc/apache2/ports.conf 2>/dev/null || true\nfind /etc/apache2/sites-enabled/ -name "*.conf" -exec sed -i "s/:80>/:$PORT>/g" {} \\;\nexec /entrypoint.sh apache2-foreground\n' > /start.sh && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
