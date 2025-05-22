FROM php:8.2-fpm-alpine

ENV COMPOSER_MEMORY_LIMIT=-1

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    oniguruma-dev \
    libxml2-dev \
    # Additional dependencies for PHP extensions
    libwebp-dev \
    zlib-dev \
    libxslt-dev

# Configure GD with FreeType, JPEG, and WebP support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# Install PHP extensions one by one (to isolate failures)
RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql
RUN docker-php-ext-install -j$(nproc) mbstring bcmath xml ctype tokenizer
RUN docker-php-ext-install -j$(nproc) zip
RUN docker-php-ext-install -j$(nproc) gd

# Install additional extensions if needed (e.g., xsl)
RUN docker-php-ext-install -j$(nproc) xsl

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY . .

RUN mkdir -p storage/logs bootstrap/cache && chown -R www-data:www-data storage bootstrap/cache

RUN composer install --no-interaction --prefer-dist --optimize-autoloader

EXPOSE 9000

CMD ["php-fpm"]
