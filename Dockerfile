FROM mautic/mautic:6.0-apache

# Fix the Apache MPM conflict on Railway.
# The Mautic entrypoint re-enables both mpm_event and mpm_prefork at runtime.
# We inject a fix into the apache2 binary wrapper so mpm_event is always disabled.

RUN a2dismod mpm_event mpm_worker 2>/dev/null || true && \
    a2enmod mpm_prefork 2>/dev/null || true && \
    # Patch the apache2ctl to always disable mpm_event before starting
    echo '#!/bin/bash' > /usr/local/bin/apache2-foreground-wrapper && \
    echo 'a2dismod mpm_event mpm_worker 2>/dev/null || true' >> /usr/local/bin/apache2-foreground-wrapper && \
    echo 'a2enmod mpm_prefork 2>/dev/null || true' >> /usr/local/bin/apache2-foreground-wrapper && \
    echo 'exec /usr/sbin/apache2 -DFOREGROUND "$@"' >> /usr/local/bin/apache2-foreground-wrapper && \
    chmod +x /usr/local/bin/apache2-foreground-wrapper && \
    # Replace the apache2-foreground script that Mautic entrypoint calls
    cp /usr/local/bin/apache2-foreground /usr/local/bin/apache2-foreground.orig && \
    cp /usr/local/bin/apache2-foreground-wrapper /usr/local/bin/apache2-foreground

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
