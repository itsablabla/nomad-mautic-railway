FROM mautic/mautic:6.0-apache

# Mautic 6.0 - MPM conflict fixed in this release
# Fix PORT binding for Railway's dynamic port assignment
RUN printf '#!/bin/bash\nPORT=${PORT:-80}\nsed -i "s/Listen 80/Listen $PORT/g" /etc/apache2/ports.conf 2>/dev/null || true\nfind /etc/apache2/sites-enabled/ -name "*.conf" -exec sed -i "s/:80>/:$PORT>/g" {} \\; 2>/dev/null || true\nexec /entrypoint.sh apache2-foreground\n' > /start.sh && chmod +x /start.sh

# Ensure correct permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["/start.sh"]
