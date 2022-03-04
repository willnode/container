FROM rockylinux:latest
MAINTAINER Wildan M <willnode@wellosoft.net>
ARG WEBMIN_ROOT_HOSTNAME
ARG WEBMIN_ROOT_PASSWORD
ARG WEBMIN_ROOT_PORT
WORKDIR /root

# GNU tools
RUN dnf install -y curl git nano vim wget openssl whois zip unzip tar
RUN dnf install -y which gcc gcc-c++ gnupg2 gpg make cmake

# SystemD replacement
RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/v1.5.4505/files/docker/systemctl3.py
RUN chmod +x systemctl3.py && cp -f systemctl3.py /usr/bin/systemctl && rm -f systemctl3.py

# Virtualmin
RUN wget http://software.virtualmin.com/gpl/scripts/install.sh
RUN /bin/sh install.sh --bundle LEMP --hostname ${WEBMIN_ROOT_HOSTNAME} --minimal --force
RUN rm install.sh

# EPEL
RUN dnf install -y dnf-utils
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(< /etc/redhat-release tr -dc '0-9.'|cut -d \. -f1).noarch.rpm
RUN dnf-config-manager --enable epel
RUN dnf clean all && dnf update -y

# Nodejs & C++
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(< /etc/redhat-release tr -dc '0-9.'|cut -d \. -f1).noarch.rpm
RUN curl --fail -sSL -o setup-nodejs https://rpm.nodesource.com/setup_14.x
RUN bash setup-nodejs
RUN dnf install -y nodejs

# Python
RUN dnf -y install python36 python36-pip
RUN dnf -y install python38 python38-pip

# Ruby
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
RUN curl -sSL https://get.rvm.io | bash -s stable
# relogin from now
RUN usermod -a -G rvm `whoami`
RUN rvm install ruby
RUN rvm --default use ruby

# PHP
RUN dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
RUN dnf module reset -y php
RUN dnf module enable php:remi-7.4
RUN dnf install -y php php-bcmath php-cli php-common php-devel php-fpm php-gd php-intl php-json php-mbstring php-mysqlnd php-opcache php-pdo php-pear php-pecl-igbinary php-pecl-memcached php-pecl-msgpack php-pecl-yaml php-pecl-zip php-pgsql php-process php-xml php-xmlrpc
RUN dnf install -y php56-php php56-php-bcmath php56-php-cli php56-php-common php56-php-devel php56-php-fpm php56-php-gd php56-php-intl php56-php-json php56-php-mbstring php56-php-mysqlnd php56-php-opcache php56-php-pdo php56-php-pear php56-php-pecl-igbinary php56-php-pecl-memcached php56-php-pecl-msgpack php56-php-pecl-yaml php56-php-pecl-zip php56-php-pgsql php56-php-process php56-php-xml php56-php-xmlrpc
RUN dnf install -y php80-php php80-php-bcmath php80-php-cli php80-php-common php80-php-devel php80-php-fpm php80-php-gd php80-php-intl php80-php-json php80-php-mbstring php80-php-mysqlnd php80-php-opcache php80-php-pdo php80-php-pear php80-php-pecl-igbinary php80-php-pecl-memcached php80-php-pecl-msgpack php80-php-pecl-yaml php80-php-pecl-zip php80-php-pgsql php80-php-process php80-php-xml php80-php-xmlrpc
RUN dnf install -y php81-php php81-php-bcmath php81-php-cli php81-php-common php81-php-devel php81-php-fpm php81-php-gd php81-php-intl php81-php-json php81-php-mbstring php81-php-mysqlnd php81-php-opcache php81-php-pdo php81-php-pear php81-php-pecl-igbinary php81-php-pecl-memcached php81-php-pecl-msgpack php81-php-pecl-yaml php81-php-pecl-zip php81-php-pgsql php81-php-process php81-php-xml php81-php-xmlrpc

# Passenger Nginx
RUN curl --fail -sSLo /etc/dnf.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/dnf/definitions/el-passenger.repo
RUN dnf install -y nginx-mod-http-passenger || dnf-config-manager --enable cr && dnf install -y nginx-mod-http-passenger
RUN systemctl restart nginx

# Firewall
RUN systemctl stop firewalld
RUN systemctl disable firewalld
RUN systemctl mask --now firewalld

RUN dnf install -y iptables-services
RUN systemctl start iptables
RUN systemctl start ip6tables
RUN systemctl enable iptables
RUN systemctl enable ip6tables

# Postgresql
RUN dnf install -y postgresql-server postgresql-contrib
RUN postgresql-setup initdb
RUN systemctl enable postgresql
RUN systemctl start postgresql

# Disable stuff from webmin
RUN systemctl stop clamav
RUN systemctl disable clamav
RUN systemctl stop dovecot
RUN systemctl disable dovecot
RUN systemctl stop fail2ban
RUN systemctl disable fail2ban
RUN systemctl stop postfix
RUN systemctl disable postfix
RUN systemctl stop httpd
RUN systemctl disable httpd
RUN systemctl stop httpd
RUN systemctl disable httpd

RUN dnf install -y composer go rustc cargo rake
RUN npm install -g yarn

# set root password
WORKDIR /usr/libexec/webmin
RUN ./changepass.pl /etc/webmin root ${WEBMIN_ROOT_PASSWORD}
WORKDIR /root

# Temporary fix for nginx
RUN yum downgrade wbm-virtualmin-nginx-2.21 -y
RUN yum downgrade wbm-virtualmin-nginx-ssl-1.15 -y

# Git good default config
RUN git config --global pull.rebase false

# # etc
# RUN alternatives --config python

ENTRYPOINT ["/usr/bin/systemctl","default","--init"]
