FROM php:8.2-fpm

ENV COMPOSER_MEMORY_LIMIT=-1

# Install system dependencies and PHP build dependencies using apt
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    gcc \
    g++ \
    make \
    bash \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    libonig-dev \
    libxml2-dev \
    libwebp-dev \
    zlib1g-dev \
    libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure GD with FreeType, JPEG, and WebP support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# Install PHP extensions
# Configure GD with FreeType, JPEG, and WebP support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# Install PHP extensions including exif
RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql mbstring bcmath xml ctype zip gd xsl exif

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY . .

# Fix permissions for Laravel storage and cache folders
RUN mkdir -p storage/logs bootstrap/cache && chown -R www-data:www-data storage bootstrap/cache

# Install composer dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

RUN php artisan storage:link

EXPOSE 9000

CMD ["php-fpm"]
