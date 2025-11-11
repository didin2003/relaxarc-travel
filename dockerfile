# Use official PHP 8.2 FPM image
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nodejs \
    npm \
 && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy app files
COPY . .

# Ensure .env exists
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Install PHP dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

# define namespace
RUN composer dump-autoload
RUN php artisan optimize:clear

# Generate application key
RUN php artisan key:generate || true

# Set permissions for Laravel storage and cache
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

ENV NODE_OPTIONS=--openssl-legacy-provider
# Install and build frontend assets
RUN npm install && npm run production
RUN npm prune --production

# Clear and cache config/routes/views for production
RUN php artisan config:cache \
 && php artisan route:cache \
 && php artisan view:cache

# Expose port 8000
EXPOSE 8000

# Start Laravel development server
CMD ["php-fpm"]
