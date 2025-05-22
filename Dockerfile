FROM php:8.2-fpm

ENV COMPOSER_MEMORY_LIMIT=-1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    libonig-dev \
    libxml2-dev

# Configure GD with explicit FreeType and JPEG support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Install PHP extensions one by one (to isolate failures)
RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql
RUN docker-php-ext-install -j$(nproc) mbstring bcmath xml ctype tokenizer
RUN docker-php-ext-install -j$(nproc) zip
RUN docker-php-ext-install -j$(nproc) gd

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY . .

RUN mkdir -p storage/logs bootstrap/cache && chown -R www-data:www-data storage bootstrap/cache

RUN composer install --no-interaction --prefer-dist --optimize-autoloader

EXPOSE 9000

CMD ["php-fpm"]
