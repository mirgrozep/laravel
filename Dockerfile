FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ... [keep your existing packages] ...
    nginx \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions setup
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql mbstring bcmath xml ctype zip gd xsl exif

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Nginx config
COPY nginx.conf /etc/nginx/sites-available/default

WORKDIR /var/www

# Copy application files
COPY . .

# Fix permissions (crucial fix)
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Install dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Generate application key if not exists
RUN if [ ! -f .env ]; then cp .env.example .env && php artisan key:generate; fi

# Storage link
RUN php artisan storage:link

ENV COMPOSER_MEMORY_LIMIT=-1

EXPOSE 80

CMD ["sh", "-c", "php-fpm & nginx -g 'daemon off;'"]