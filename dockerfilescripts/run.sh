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
    chmod 600 ~/.ssh/id_rsa
  fi
}

# Copy Drush settings from host
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_drush ()
{
  local path="$1/.drush"
  if [ -d $path ]; then
    echo "Copying Drush settings in $path from host..."
    cp -r $path ~
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

# Copy SSH keys from host if available
copy_ssh_key '/.home/.ssh' # Generic
copy_ssh_key '/.home-linux/.ssh' # Linux (docker-compose)
copy_ssh_key '/.home-b2d/.ssh' # boot2docker (docker-compose)

# Copy Drush settings from host if available
copy_dot_drush '/.home' # Generic
copy_dot_drush '/.home-linux' # Linux (docker-compose)
copy_dot_drush '/.home-b2d' # boot2docker (docker-compose)
copy_dot_drush '/.home-localdev'   # Drush overrides from local environment home folder

# Copy Bash settings from artificial $HOME folder if available
copy_dot_bash '/.home-localdev'
cp  /.home-localdev/{.b,.dr,.p}*  ~ 2>/dev/null 

# Copy scripts from artificial $HOME folder if available
cp  /.home-localdev/bin/* ~/bin/ 2>/dev/null

# Below this is the original startup. Above are the commands brought in from the cli container.
VOLUME_HOME="/data" 

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db > /dev/null 2>&1
    echo "=> Done!"
    /create_first_admin_user.sh
    /create_database_and_users.sh
else
    echo "=> Using an existing volume of MySQL"
fi
echo "=> Starting Supervisor daemon"
exec supervisord -n

