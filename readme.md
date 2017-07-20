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

## Building

Build an image - `docker build -t "symbiote/ss-dev" .`


## Running on Linux

Run a new container with your local www directory bound to /var/www/dynamic. 
Apache resolves URLs to virtual hosts in the form

`{sub-domain}.{top-domain}.symlocal`

to

`/var/www/dynamic/{top-domain}/{sub-domain}`

Expose a separate mysql docker if you wish to develop with mysql. 

If you want to use SSH from within the container, run ssh-agent on your host 
and bind the socket in

```
docker run -d --name webserver -p 80:80 --link mysql-5-6:mysql \
  -v /home/{user}/www:/var/www/dynamic \
  -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
  symbiote/ss-dev
```

## Running on Windows

Run the following command in Windows Powershell.

`docker run -d --name webserver -p 80:80 --link mysql-5-6:mysql -v /c/Users/your_username_here/www:/var/www/dynamic -v /c/Users/your_username_here/.ssh:/root/.ssh/keys symbiote/ss-dev`

**Warnings:**
- Running in Git Bash caused errors to occur when the container installs Composer, PowerShell just worked.
- I placed my 'www' in `C:/Users/your_username_here` as users reported weird permission issues. Not sure if this has been fixed in later Docker versions.
- SSH keys are copied to /root/.ssh/keys on remote to avoid permission issues blocking use of keys. They are copied to /root/.ssh/ by the startup script.

## Run / Configure MySQL

Setup a MySQL container by running the following

`docker run -d --name mysql-5-6 -e MYSQL_ROOT_PASSWORD=password mysql:5.6`

Then in your local.conf.php files, set it up like so below.

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

## CLI access

To run things from the CLI, you can run 

`docker exec -it webserver bash`

# Configuration

The container is configured to execute a script that creates a user mapped
to the user that _started_ the container, and sets apache to run as that user. 
This means that all things created by the webserver are owned by user that
started the container. 
