#!/bin/bash

### Commands brought in from the Drude cli container.
# Default SSH key name
if [ -z $SSH_KEY_NAME ]; then SSH_KEY_NAME='id_rsa'; fi
echo "Using SSH key name: $SSH_KEY_NAME"

# Copy SSH key pairs.
# @param $1 path to .ssh folder
copy_ssh_key ()
{
  local path="$1/$SSH_KEY_NAME"
  if [ -f $path ]; then
    echo "Copying SSH key $path from host..."
    cp $path ~/.ssh/id_rsa
    cp ${path}.pub ~/.ssh/id_rsa.pub
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
  fi
}

# Copy Drush settings from host
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_drush ()
{
  local path="$1/.drush"
  if [ -d $path ]; then
    echo "Copying Drush settings in $path from host..."
     rsync -r $path ~ --exclude=cache
  fi
}
# Copy Fish Shell settings from host
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_config_fish ()
{
  local path="$1/.config/fish"
  if [ -d $path ]; then
    echo "Copying Drush settings in $path from host..."
     cp -r ${path}/* ~/.config/fish/
  fi
}
# Copy bash configuration files from artificial $HOME in docker environment
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_bash ()
{
  local path="$1/"
  if [ -d $path ]; then
    echo "Copying Bash settings in $path from artificial \$HOME directory..."
    cp -r $path/. ~
  fi
}

# Reset home directory ownership
gosu root chown $(id -u):$(id -g) -R ~

# Copy SSH keys from host if available
copy_ssh_key '/.home/.ssh' # Generic
copy_ssh_key '/.home-linux/.ssh' # Linux (docker-compose)
copy_ssh_key '/.home-b2d/.ssh' # boot2docker (docker-compose)

# Copy Drush settings from host if available
copy_dot_drush '/.home' # Generic
copy_dot_drush '/.home-linux' # Linux (docker-compose)
copy_dot_drush '/.home-b2d' # boot2docker (docker-compose)
copy_dot_drush '/.home-localdev'   # Drush overrides from local environment home folder

# Copy Fish settings from host if available
mkdir -p /home/docker/.config/fish
copy_dot_config_fish '/.home-linux'

# Copy Bash settings from artificial $HOME folder if available
copy_dot_bash '/.home-localdev'
cp  /.home-localdev/{.b,.dr,.p}* ~ 2>/dev/null

# Copy scripts from artificial $HOME folder if available
cp  /.home-localdev/bin/* ~/bin/ 2>/dev/null

# Reset home directory ownership
gosu root chown $(id -u):$(id -g) -R ~

# Reset webroot directory ownership
gosu root chown $(id -u):$(id -g) /var/www

# Check if the docroot exists, otherwise create it.
if [[ ! -d /var/www/docroot ]]; then
  mkdir -p /var/www/docroot
fi

# Below this is the original startup. Above are the commands brought in from the cli container.
VOLUME_HOME="/data" 

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    gosu root mysql_install_db > /dev/null 2>&1
    echo "=> Done!"
    gosu root /create_first_admin_user.sh
    gosu root /create_database_and_users.sh
else
    echo "=> Using an existing volume of MySQL"
fi
# Fix MySQL socket ownership issues.
if [ -d /var/run/mysqld ]; then
  gosu root chown mysql:root /var/run/mysqld
  gosu root chmod u+s /var/run/mysqld
fi
echo "=> Starting Supervisor daemon"
#exec supervisord -n

exec  gosu root supervisord -n
