FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    gcc \
    g++ \
    make \
    bash \
    libpng-dev \
    libjpeg62-turbo-dev \
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
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Configure GD with correct library names
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    mbstring \
    bcmath \
    xml \
    ctype \
    zip \
    gd \
    xsl \
    exif

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Nginx config
COPY nginx.conf /etc/nginx/sites-available/default

WORKDIR /var/www

# Copy application
COPY . .

# Fix Laravel storage permissions (critical fix)
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Install dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Generate key if missing
RUN if [ ! -f .env ]; then cp .env.example .env && php artisan key:generate; fi

# Create storage link
RUN php artisan storage:link

ENV COMPOSER_MEMORY_LIMIT=-1

EXPOSE 80

CMD ["sh", "-c", "php-fpm & nginx -g 'daemon off;'"]