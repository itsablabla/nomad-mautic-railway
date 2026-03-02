FROM mautic/mautic:5.2-apache

# Fix Apache MPM conflict - disable mpm_event and mpm_prefork, enable only mpm_prefork
RUN a2dismod mpm_event mpm_worker 2>/dev/null || true && \
    a2enmod mpm_prefork && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2enmod expires

# Ensure PHP is enabled
RUN a2enmod php8.1 2>/dev/null || a2enmod php8.2 2>/dev/null || a2enmod php8.0 2>/dev/null || true

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
