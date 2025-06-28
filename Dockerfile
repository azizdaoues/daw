FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    libzip-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

COPY --from=composer:2.5 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY . .

RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Créer les dossiers nécessaires et définir les permissions
RUN mkdir -p /var/www/storage/logs \
    && mkdir -p /var/www/storage/framework/cache \
    && mkdir -p /var/www/storage/framework/sessions \
    && mkdir -p /var/www/storage/framework/views \
    && mkdir -p /var/www/bootstrap/cache

# Définir les permissions correctes
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

# Créer un script de démarrage simple
RUN echo '#!/bin/bash\n\
# Attendre que la base de données soit prête\n\
echo "Waiting for database..."\n\
sleep 10\n\
\n\
# Démarrer le serveur PHP\n\
php artisan serve --host=0.0.0.0 --port=8000' > /var/www/start.sh \
    && chmod +x /var/www/start.sh

EXPOSE 8000
CMD ["/var/www/start.sh"]
