# Apache based SilverStripe app container

Ubuntu based (for convenience...)

Contains the tools for development. NOTE - this _will_ change in future
to better support separation into production environments. This is a really
temporary solution. 

* Apache 2 with dynamic virtual hosts
* PHP 5
* XDebug
* Composer
* phing
* mysql (client libs)

# Usage

## Build an image

`docker build -t "symbiote/ss-dev" .`

NOTE: Don't forget the "." at the end, this is to build in the current directory.

## Configure your docker-compose YML

Uncomment the "volumes" config options best suited to your operating sytem.
Replace the text "your_username_here" with your username.

For Linux users, if you want to use SSH from within the container, run ssh-agent on your host 
and bind the socket in.

Once the below file is configured, simply run:
```
docker-compose up
```

You will get something like:
```
Starting nyeholt_webserver_1 ...
Starting nyeholt_mysql_1 ...
```

You can use these names to use CLI in the container like so:
```
docker exec -it nyeholt_webserver_1 bash
```
or
```
docker exec -it nyeholt_mysql_1 bash
```

```
version: '2'
services:
  webserver:
    image: "symbiote/ss-dev"
    ports:
      - "80:80"
    environment:
      # *nix /.ssh/ folder location
      - SSH_AUTH_SOCK
    volumes:
      # Example *nix configuration
      #- /home/your_username_here/www:/var/www/dynamic
      #- $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK)

      # Example Windows configuration
      #- /c/Users/your_username_here/www:/var/www/dynamic
      #- /c/Users/your_username_here/AppData/Local/Composer:/root/.composer/cache
  mysql:
    # MySQL 5.6
    # https://github.com/docker-library/mysql/tree/master/5.6
    image: "mysql:5.6"
    #volumes:
      # Sync folder with .sql dumps
      #- /c/MySQLDatabases/unzipped:/docker-entrypoint-initdb.d
    environment:
        MYSQL_ROOT_PASSWORD: "password"
```

## Windows-specific Information


**Example of directories mapping to host:**
```
C:\Users\your_username_here\www\projects\facebook  -> facebook.projects.symlocal
C:\Users\your_username_here\www\tools\adminer      -> adminer.tools.symlocal
```

**Example hosts file in C:\Windows\System32\drivers\etc\hosts**
```
127.0.0.1     facebook.projects.symlocal
127.0.0.1     adminer.tools.symlocal
```

**INSECURE: Share SSH keys from host to container: (ie. Support private Git repos)**

First thing to note, this isn't at all very secure AND you should definitely not build any images from
a container that contains your SSH keys. This is a stopgap solution until we find something better.

The SSH keys will get copied out of `/root/.ssh/keys` to `/root/.ssh` and the permissions will be fixed.

```
version: '2'
services:
  webserver:
    volumes:
      # -/c/Users/your_username_here/.ssh:/root/.ssh/keys
```

**Warnings:**
- Running in Git Bash caused errors to occur when the container installs Composer, PowerShell just worked.
- I placed my 'www' in `C:/Users/your_username_here` as users reported weird permission issues. Not sure if this has been fixed in later Docker versions.
- SSH keys are copied to /root/.ssh/keys on remote to avoid permission issues blocking use of keys. They are copied to /root/.ssh/ by the startup script.

## Configure MySQL

In your local.conf.php files, set it up like so below.

```
<?php

/*
 * Include any local instance specific configuration here - typically
 * this includes any database settings, email settings, etc that change
 * between installations. 
 */

global $databaseConfig;
$databaseConfig = array(
	"type" => "MySQLDatabase",
	"server" => "mysql", // The MySQL containers hostname
	"username" => "root",
	"password" => "password",
	"database" => "silverstripe",
);

Security::setDefaultAdmin('admin', 'admin');
// Email::setAdminEmail('admin@example.org');
define('SS_LOG_FILE', dirname(__FILE__).'/'.basename(dirname(dirname(__FILE__))).'.log');
Director::set_environment_type('dev');
```

# Old Information (needs to be re-written)

## Volume mappings

The one required mapping is your host file system's project directory to 
/var/www/dynamic in the container. In addition, the following are useful for
improved performance

* `-v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK)` Maps the host's 
  ssh-agent local socket to the container's socket dir; make sure ssh-agent is
  started on the host. Use with the accompanying environment var 
  `-e SSH_AUTH_SOCK=$SSH_AUTH_SOCK`
* `-v ~/composer-cache:/root/.composer/cache` Share composer cache locations across
  multiple contains with a folder on the host


Then hit http://sub-folder.projectdir.symlocal/ from the host. 

# Configuration

The container is configured to execute a script that creates a user mapped
to the user that _started_ the container, and sets apache to run as that user. 
This means that all things created by the webserver are owned by user that
started the container. 
