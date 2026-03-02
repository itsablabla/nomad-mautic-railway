FROM mautic/mautic:5.2-apache

# Fix Apache MPM conflict at BUILD time
RUN a2dismod mpm_event mpm_worker 2>/dev/null || true && \
    a2enmod mpm_prefork && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2enmod expires

# Ensure PHP is enabled
RUN a2enmod php8.1 2>/dev/null || a2enmod php8.2 2>/dev/null || a2enmod php8.0 2>/dev/null || true

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Create a wrapper that patches Apache BEFORE the entrypoint runs
# The Mautic entrypoint re-enables MPMs, so we must fix it AFTER entrypoint runs setup
# but BEFORE apache2-foreground is called. We do this by replacing the CMD.
RUN cat > /fix-and-start.sh << 'SCRIPT'
#!/bin/bash
set -e

# Run the Mautic entrypoint setup (without starting apache)
# The entrypoint.sh calls apache2-foreground at the end - we need to intercept that
# So we patch apache2-foreground to fix MPMs first
cat > /usr/local/bin/apache2-foreground << 'APACHE_SCRIPT'
#!/bin/bash
# Fix MPM conflict every time before Apache starts
a2dismod mpm_event mpm_worker 2>/dev/null || true
a2enmod mpm_prefork 2>/dev/null || true
# Fix PORT binding for Railway
PORT=${PORT:-80}
sed -i "s/Listen 80/Listen $PORT/g" /etc/apache2/ports.conf 2>/dev/null || true
find /etc/apache2/sites-enabled/ -name "*.conf" -exec sed -i "s/:80>/:$PORT>/g" {} \; 2>/dev/null || true
# Now start Apache for real
exec /usr/sbin/apache2 -D FOREGROUND "$@"
APACHE_SCRIPT
chmod +x /usr/local/bin/apache2-foreground

# Now run the original entrypoint
exec /entrypoint.sh apache2-foreground
SCRIPT
RUN chmod +x /fix-and-start.sh

EXPOSE 80

CMD ["/fix-and-start.sh"]
