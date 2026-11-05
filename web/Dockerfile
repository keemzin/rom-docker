FROM php:8.2-fpm-bookworm

# Install Nginx, Supervisor, and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    curl \
    git \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    default-mysql-client \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Install required PHP extensions
RUN docker-php-ext-install pdo_mysql mysqli mbstring exif pcntl bcmath gd zip

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

# Configure Nginx & PHP
RUN mkdir -p /www/wwwroot /var/log/nginx /var/run/php \
    && chown -R www-data:www-data /www

# Copy configurations
COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d/ /etc/nginx/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /www/wwwroot

EXPOSE 80 81 5556

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
