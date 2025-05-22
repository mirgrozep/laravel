FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libxslt1-dev \
    nginx \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd xsl zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy composer files first
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install --no-interaction --optimize-autoloader --no-scripts

# Copy application files
COPY . .

# Fix permissions (critical step)
RUN mkdir -p storage/framework/{sessions,views,cache} && \
    chown -R www-data:www-data /var/www && \
    chmod -R 775 storage bootstrap/cache

# Generate application key and cache
RUN php artisan key:generate && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Nginx config
COPY nginx.conf /etc/nginx/sites-available/default

EXPOSE 80

CMD ["sh", "-c", "php-fpm & nginx -g 'daemon off;'"]