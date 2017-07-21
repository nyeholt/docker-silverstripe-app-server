FROM ubuntu:14.04

# allows the use of the 'source' command. 
RUN rm /bin/sh && ln -s /bin/bash /bin/sh


RUN apt-get update  && apt-get install -y \
    software-properties-common \
    apt-transport-https \
    build-essential \
    ca-certificates \
    vim \
    apache2 \
    git \
    curl \ 
    wget \ 
    mysql-client \
    php5 php5-cli php5-sqlite  php5-tidy php5-mysql php5-ldap php5-redis php5-json php5-mcrypt  php5-curl  php5-xdebug  php5-pspell  php5-gd  php5-dev \
    openjdk-7-jdk \
 && php5enmod mcrypt \
 && rm -rf /var/lib/apt/lists/*

# Setup Java / Solr config
RUN mkdir /usr/java && ln -s /usr/lib/jvm/java-7-openjdk-amd64 /usr/java/default
EXPOSE 8983

# Setup apache modules
RUN a2enmod rewrite && a2enmod headers && a2enmod vhost_alias && a2enmod expires 

# Set timezone
RUN echo 'date.timezone = Australia/Melbourne' > /etc/php5/apache2/conf.d/date.ini
RUN echo 'date.timezone = Australia/Melbourne' > /etc/php5/cli/conf.d/date.ini

# Developer centric dynamic vhost config. 
RUN mkdir /var/www/dynamic && chown www-data:www-data /var/www/dynamic
COPY apache_dynamic_vhosts /etc/apache2/sites-available/000-default.conf
# end_developer

COPY startup /usr/local/bin/startup
RUN chmod +x /usr/local/bin/startup

EXPOSE 80
EXPOSE 443

# Composer - can be a separate layer? 
ADD install-composer.sh /tmp/

RUN chmod +x /tmp/install-composer.sh && /tmp/install-composer.sh && composer global require phing/phing
RUN echo "export PATH=\$PATH:~/.composer/vendor/bin/" >> ~/.bashrc

# The path that will be used to make Apache run under that user
ENV VOLUME_PATH /var/www/dynamic

# Debugger settings. Need to split to a developer's dockerfile
ENV XDEBUGINI_PATH=/etc/php5/mods-available/xdebug.ini

RUN echo "xdebug.remote_enable=on" >> $XDEBUGINI_PATH \
 && echo "xdebug.remote_autostart=off" >> $XDEBUGINI_PATH \
 && echo "xdebug.remote_handler=dbgp" >> $XDEBUGINI_PATH \
 && echo "xdebug.remote_host="`/sbin/ip route|awk '/default/ { print $3 }'` >> $XDEBUGINI_PATH

# Set start directory
WORKDIR /var/www/dynamic

CMD ["/usr/local/bin/startup"]
