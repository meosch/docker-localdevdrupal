Drupal development with Docker
==============================
NOTE: This is a work in progress and the Readme may not be totally up to date.
==============================
Quick and easy to use Docker container for your local Drupal development. It contains a LAMP stack and an SSH server, along with an up to date version of Drush. It is based on [Debian Wheezy](https://wiki.debian.org/DebianWheezy).

Summary
-------

This image contains:

* Apache 2.2
* MySQL 5.6
* PHP 5.6
* Drupal 7.x, [Web Experience Toolkit distribution](https://www.drupal.org/project/wetkit) 4.0, development edition (optionally supports current Drupal)
* [Composer](https://getcomposer.org/)
* Drush 7.x version
* Adminer latest
* Supervisor
* nano, vim, git and Mercurial (hg)

When launched, the container will contain a ready-to-install Drupal distribution, with no database configured. You need to first create a database by using Adminer off the web root at `/adminer.php`, then select one of PostgreSQL, MySQL or SQLite as a database, when kicking off a Drupal install.

### Passwords

* Drupal: `admin:admin`
* MySQL: `root:` (no password)
* SSH: `root:root`
* Supervisor `supervisor:supervisor`

### Exposed ports

* 80 (Apache)
* 22 (SSH)
* 3306 (MySQL)
* 9001 (Supervisor)

Installation
------------

### Github

https://github.com/meosch/docker-localdevdrupal

Clone the repository locally and build it:

    git clone https://github.com/meosch/docker-localdevdrupal.git
	cd docker-localdevdrupal
	docker build -t yourname/drupal .

### Docker repository

  https://hub.docker.com/r/meosch/localdevdrupal/


Get the image:

  docker pull meosch/localdevdrupal

Running the container
---------------------

The container exposes its `80` port (Apache), its `3306` port (MySQL), its `9001` port (Supervisor) and its `22` port (SSH). Make good use of this by forwarding your local ports. You should at least forward to port `80` (using `-p local_port:80`, like `-p 8080:80`). A good idea is to also forward port `22`, so you can use Drush from your local machine using aliases, and directly execute commands inside the container, without attaching to it.

Here's an example just running the container and forwarding `localhost:8080`, `localhost:2222`, `localhost:9291` to the container:

	docker run --rm --name youralias -p 8080:80 -p 2222:22 -p 9201:9001 yourname/drupal

### MySQL and Adminer

[Adminer](http://www.adminer.org/) is a tool that can be used to administer MySQL, PostgreSQL and SQLite databases, contained in a single file of PHP. Adminer is aliased to the web root at `/adminer.php`.

The MySQL port `3306` is exposed. The root account for MySQL is `root` (no password).

### Supervisor

[Supervisor](http://supervisord.org/) provides a rudimentary web UI over port `9001` to manage several of the server processes (Apache, MySQL, PostgreSQL, sshd, Solr). It can be found over http `localhost:9201` in the above example, logging in with the id `supervisor` and the password also `supervisor`.

Tutorial
--------

This container is based on a container found here:

https://github.com/jmdeleon/docker-drupal

which was based on a container found here:

https://github.com/wadmiraal/docker-drupal

You can read more about the original container this is based on here: 

http://wadmiraal.net/lore/2015/03/27/use-docker-to-kickstart-your-drupal-development/
