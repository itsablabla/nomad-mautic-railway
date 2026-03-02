FROM mautic/mautic:4.4-apache

# Mautic 4.4 LTS - stable, no MPM conflict on Railway
# Fix PORT binding for Railway's dynamic port assignment
RUN echo '#!/bin/bash\n\
PORT=${PORT:-80}\n\
sed -i "s/Listen 80/Listen $PORT/g" /etc/apache2/ports.conf 2>/dev/null || true\n\
find /etc/apache2/sites-enabled/ -name "*.conf" -exec sed -i "s/:80>/:$PORT>/g" {} \\; 2>/dev/null || true\n\
exec /entrypoint.sh apache2-foreground\n\
' > /start.sh && chmod +x /start.sh

# Ensure correct permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["/start.sh"]
