FROM debian:wheezy
MAINTAINER Frederick J. Henderson <frederickjh@henderson-meier.org>
ENV DEBIAN_FRONTEND noninteractive
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install base packages
RUN apt-get update && apt-get install -y \
	build-essential \
#	vim \
	curl \
	wget \
	unzip \
	nano \
	openssh-server \
	openjdk-7-jdk \
	python-pip \
	python-virtualenv \
	supervisor

# Install updated Git and Mercurial (hg) from Debian backports repository
RUN echo "deb http://http.debian.net/debian wheezy-backports main" > /etc/apt/sources.list.d/wheezy-backports.list
RUN apt-get update -qq && apt-get -t wheezy-backports install -y -qq git mercurial

# Install updated PHP 5.6 and Apache from dotdeb.org repository
RUN echo -e '\n\ndeb http://packages.dotdeb.org wheezy all\ndeb-src http://packages.dotdeb.org wheezy all\n\n' >>  /etc/apt/sources.list
RUN echo -e '\n\ndeb http://packages.dotdeb.org wheezy-php56 all\ndeb-src http://packages.dotdeb.org wheezy-php56 all\n\n' >>  /etc/apt/sources.list
RUN wget --quiet -O - https://www.dotdeb.org/dotdeb.gpg | apt-key add -
# Install newer version of fish shell
RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/2/Debian_7.0/ /' >> /etc/apt/sources.list.d/fish.list
RUN wget --quiet -O - http://download.opensuse.org/repositories/shells:fish:release:2/Debian_7.0/Release.key | apt-key add -
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
	apache2 \
#	sqlite3 \
	libapache2-mod-php5 \
#	mysql-server \
	mysql-client \
	php5-fpm \
	php5-dev \
	php-pear \
	php5-cli \
	php5-mysql \
	php5-gd \
	php5-curl \
	php5-mcrypt \
#	php5-sqlite \
  sudo \
  fish

RUN \
# Install gosu and give access to the users group to use it. gosu will be used to run services as a different user. From blinkreaction/docker-drupal-base - docker-drupal-base/jessie/Dockerfile
curl -sSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu && \
    chown root:users /usr/local/bin/gosu && \
    chmod +sx /usr/local/bin/gosu

RUN \
    # Create a non-root user with access to sudo and the default group set to 'users' (gid = 100)
    useradd -m -s /bin/bash -g users -G sudo -p docker docker && \
    # Add "docker" user to sudoers file to allow super user permissions
    echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install github's hub. A command-line wrapper for git that makes you better at GitHub.
RUN wget -O /tmp/hub-linux-amd64-2.2.5.tgz https://github.com/github/hub/releases/download/v2.2.5/hub-linux-amd64-2.2.5.tgz
RUN cd /tmp
RUN tar -zxvf /tmp/hub-linux-amd64-2.2.5.tgz
RUN cp ./hub-linux-amd64-2.2.5/bin/hub /usr/local/sbin
RUN cp ./hub-linux-amd64-2.2.5/etc/hub.bash_completion.sh /usr/local/sbin
RUN rm -rf ./hub-linux-amd64-2.2.5
RUN rm /tmp/hub-linux-amd64-2.2.5.tgz

RUN apt-get autoremove && apt-get clean

# Setup PHP
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php5/cli/php.ini
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php5/apache2/php.ini
RUN sed -i 's/memory_limit = 128M/memory_limit = 384M/' /etc/php5/apache2/php.ini
RUN sed -i 's/max_execution_time = 30/max_execution_time = 600/' /etc/php5/apache2/php.ini
RUN sed -i 's/max_input_time = 60/max_input_time = 120/' /etc/php5/apache2/php.ini
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 300M/' /etc/php5/apache2/php.ini
RUN sed -i 's/zlib.output_compression = Off/zlib.output_compression = On/' /etc/php5/apache2/php.ini
RUN sed -i 's/;date.timezone =/date.timezone = "UTC"/' /etc/php5/apache2/php.ini
RUN sed -i 's/;opcache.memory_consumption=64/opcache.memory_consumption=128/' /etc/php5/apache2/php.ini
RUN sed -i 's/user = /c user = docker/' /etc/php5/apache2/php.ini

# Setup Apache
# In order to run our Simpletest tests, we need to make Apache
# listen on the same port as the one we forwarded. Because we use
# 8080 by default, we set it up for that port.
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default
RUN echo "Listen 8080" >> /etc/apache2/ports.conf
RUN sed -i 's/VirtualHost \*:80/VirtualHost \*/' /etc/apache2/sites-available/default
RUN sed -i 's@DocumentRoot /var/www@DocumentRoot /var/www/docroot@' /etc/apache2/sites-available/default
RUN sed -i 's@Directory /var/www/@Directory /var/www/docroot@' /etc/apache2/sites-available/default
RUN echo -e '*\n' | a2enmod
# Add www-data Apache2 user to "users" group (along with the "docker" user)
RUN usermod -a -G users www-data

# Some Environment Variables
ENV    DEBIAN_FRONTEND noninteractive

# MySQL Installation
RUN apt-get update
RUN echo "mysql-server mysql-server/root_password password " | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password " | debconf-set-selections
RUN apt-get install -y mysql-server

# Set the configuration
ADD dockerfilescripts/my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 644 /etc/mysql/conf.d/my.cnf

# Small issue with mysql_install_db on
# https://github.com/gplessis/dotdeb-mysql/issues/11
RUN cp /usr/share/doc/mysql-server-5.6/examples/my-default.cnf /usr/share/mysql/

ADD dockerfilescripts/run.sh /run.sh
ADD dockerfilescripts/create_first_admin_user.sh /create_first_admin_user.sh
ADD dockerfilescripts/create_database_and_users.sh /create_database_and_users.sh
RUN chmod 755 /*.sh

# Expose port and volumes
EXPOSE 3306
VOLUME ["/var/log/mysql", "/etc/mysqld", "/var/run/mysqld"]



# Setup MySQL, bind on all addresses
RUN sed -i -e 's/^bind-address\s*=\s*127.0.0.1/#bind-address = 127.0.0.1/' /etc/mysql/my.cnf

# Setup SSH.
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
RUN mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Setup PHP support for uploadprogress
RUN echo -e '\n' | pecl install uploadprogress
RUN echo -e '\nextension = uploadprogress.so\n\n' >> /etc/php5/apache2/php.ini

# Setup Supervisor
RUN echo -e '\n[inet_http_server]\nport = *:9001\nusername = supervisor\npassword = supervisor\n\n' >> /etc/supervisor/supervisord.conf
RUN echo -e '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
RUN echo -e '[program:mysql]\ncommand=/usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
RUN echo -e '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf

# Download Drupal
RUN mkdir -p /var/www/public_html
#RUN rm -rf /var/www
#RUN cd /var && \
# Download the Web Experience Toolkit Drupal distribution
#	drush dl wetkit-7.x-4.x-dev && mv /var/wetkit* /var/www
# Replace the line above with the line below to download the stock Drupal core distribution
#	drush dl drupal && mv /var/drupal* /var/www
# RUN mkdir -p /var/www/sites/default/files && \
#	chmod a+w /var/www/sites -R && \
#	mkdir /var/www/sites/all/modules/contrib -p && \
#	mkdir /var/www/sites/all/modules/custom && \
#	mkdir /var/www/sites/all/modules/features && \
#	mkdir /var/www/sites/all/themes/contrib -p && \
#	mkdir /var/www/sites/all/themes/custom && \
RUN \

    chown -R docker:www-data /var/www/ && \
    chmod g+w -R /var/www/ && \
    chmod g+s /var/www

# Setup Adminer and phpinfo() aliases
RUN mkdir /usr/share/adminer
RUN wget -c http://www.adminer.org/latest.php -O /usr/share/adminer/adminer.php
RUN echo -e '<?php phpinfo(); ?>' >> /usr/share/adminer/phpinfo.php
RUN echo -e 'Alias /phpinfo /usr/share/adminer/phpinfo.php' > /etc/apache2/mods-available/adminer.load
RUN echo -e 'Alias /adminer /usr/share/adminer/adminer.php' >> /etc/apache2/mods-available/adminer.load
RUN echo -e '*\n' | a2enmod
RUN service apache2 restart
RUN ln -s -T /var/www/adminer.sql.gz /usr/share/adminer/adminer.sql.gz
RUN ln -s -T /var/www/adminer.sql /usr/share/adminer/adminer.sql


# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
# Add composer bin directory to PATH
ENV PATH /home/docker/.composer/vendor/bin:$PATH

RUN  mkdir /.home-linux
RUN  mkdir /.home-localdev
RUN  gosu root chown docker:users /.home-linux
RUN  gosu root chown docker:users /.home-localdev

###### All further RUN commands will run as the "docker" user ######
USER docker

# Fix permissions
RUN gosu root chown -R docker:users /home/docker

# Install Drush 8 as default
 RUN composer global require drush/drush:8.* && \

# Legacy Drush versions (6 and 7)
  mkdir $HOME/drush6 && cd $HOME/drush6 && composer require drush/drush:6.* && \
  mkdir $HOME/drush7 && cd $HOME/drush7 && composer require drush/drush:7.* && \

# Drupal Coder w/ a matching version of PHP_CodeSniffer
  composer global require drupal/coder && \
  phpcs --config-set installed_paths $HOME/.composer/vendor/drupal/coder/coder_sniffer && \
  echo "alias drupalcs=\"phpcs --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,css,info,txt'\"" >> $HOME/.bash_aliases

# Install Drupal Console.
RUN composer global require drupal/console:@stable
RUN composer global update

# Setup SSH for user docker
RUN mkdir -p /home/docker/.ssh/ && touch /home/docker/.ssh/authorized_keys

# Fix permissions
RUN gosu root chown -R docker:users /home/docker

# Set TERM so text editors/etc. can be used
ENV TERM xterm

# Install Drupal
# RUN cd /var/www && drush si -y minimal --db-url=mysql://root:@localhost/drupal --account-pass=admin

# Expose application ports and start Supervisor to manage service applications
EXPOSE 80 3306 22 9001 27017 28017
# Start the magic
CMD ["/run.sh"]
#CMD exec supervisord -n
