FROM mautic/mautic:6.0-apache

# Root cause fix: APACHE_RUN_DIR is defined in /etc/apache2/envvars but not
# sourced when apache2 is called directly, causing DefaultRuntimeDir to fail.
# Solution: write a proper apache2-foreground that sources envvars first.

RUN a2dismod mpm_event mpm_worker 2>/dev/null || true && \
    a2enmod mpm_prefork 2>/dev/null || true

# Write the fixed apache2-foreground that sources envvars before starting Apache
RUN printf '#!/bin/bash\nset -e\n. /etc/apache2/envvars\nmkdir -p "${APACHE_RUN_DIR}" 2>/dev/null || true\nmkdir -p "${APACHE_LOCK_DIR}" 2>/dev/null || true\nmkdir -p "${APACHE_LOG_DIR}" 2>/dev/null || true\na2dismod mpm_event mpm_worker 2>/dev/null || true\na2enmod mpm_prefork 2>/dev/null || true\nexec apache2 -DFOREGROUND "$@"\n' > /usr/local/bin/apache2-foreground && \
    chmod +x /usr/local/bin/apache2-foreground

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
