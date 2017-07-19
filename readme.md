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


## Running 

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
  symbiote:ss-dev
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

`docker exec -it webserver`

This will let you use php-cli against the same project folders


# Configuration

The container is configured to execute a script that creates a user mapped
to the user that _started_ the container, and sets apache to run as that user. 
This means that all things created by the webserver are owned by user that
started the container. 
