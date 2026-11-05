FROM centos:7

# Fix CentOS 7 EOL Yum Repositories to point to vault.centos.org
RUN sed -i 's/mirror.centos.org/vault.centos.org/g' /etc/yum.repos.d/*.repo && \
    sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo && \
    sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo

# Install base utilities, compiler libraries, and EPEL
RUN yum install -y \
    epel-release \
    yum-utils \
    && sed -i 's/mirror.centos.org/vault.centos.org/g' /etc/yum.repos.d/*.repo || true

RUN sed -i 's/^#baseurl=https:\/\/download.example\/pub\/epel/baseurl=https:\/\/archives.fedoraproject.org\/pub\/archive\/epel/g' /etc/yum.repos.d/epel*.repo 2>/dev/null || true \
    && sed -i 's/^mirrorlist=https/#mirrorlist=https/g' /etc/yum.repos.d/epel*.repo 2>/dev/null || true

# Install core runtime dependencies for Ragnarok M C++ servers
RUN yum install -y \
    glibc \
    glibc-devel \
    libstdc++ \
    mariadb-libs \
    libxml2 \
    jansson \
    log4cxx \
    hiredis \
    socat \
    nmap-ncat \
    which \
    psmisc \
    net-tools \
    tar \
    gzip \
    && yum clean all

# Install Remi PHP 7.0 and Swoole for trade-server
RUN yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm || true && \
    yum-config-manager --enable remi-php70 && \
    yum install -y \
    php70-php-cli \
    php70-php-common \
    php70-php-pecl-swoole2 \
    php70-php-pecl-swoole-serialize \
    php70-php-pecl-ds \
    php70-php-pecl-lua \
    php70-php-pecl-redis \
    php70-php-mysqlnd \
    php70-php-pdo \
    php70-php-json \
    php70-php-mbstring \
    && yum clean all

# Create symlinks for PHP
RUN ln -sf /opt/remi/php70/root/usr/bin/php /usr/bin/php && \
    ln -sf /opt/remi/php70/root/usr/bin/php /usr/local/bin/php

# Extract pre-compiled C++ shared libraries (protobuf, jemalloc, hiredis, etc.)
COPY libs/usr_local_lib.tar.gz /tmp/usr_local_lib.tar.gz
RUN tar -xzf /tmp/usr_local_lib.tar.gz -C /usr/local/lib && \
    rm -f /tmp/usr_local_lib.tar.gz && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf && \
    ldconfig

# Install official MySQL 5.6 client library with compress2/uncompress2 symbols
COPY libs/libmysqlclient.so.18 /usr/local/lib/libmysqlclient.so.18
RUN mkdir -p /usr/lib64/mysql && \
    cp /usr/local/lib/libmysqlclient.so.18 /usr/lib64/mysql/libmysqlclient.so.18 && \
    ldconfig

WORKDIR /RoServercode/bin/Release

# Copy Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose C++ Server & Trade Ports
# GateServer1-3, SuperServer, TradeServer, Proxies
EXPOSE 7050 7080 7081 7082 6091 26091 12053 14288

ENTRYPOINT ["/entrypoint.sh"]
