#!/bin/bash

# should be in the same directory as setup.py

echo "Installing packages..."
apt-get update
apt-get install -y python python-dev python-pip python-dbus python-opencv dbus network-manager
pip install -r requirements.txt

echo "Configuring Django..."
key=$(tr -dc "[:alpha:]" < /dev/urandom | head -c 48)
sed "s/^SECRET_KEY =.*/SECRET_KEY = '$key'/g" GoProApp/settings.py --quiet
python manage.py syncdb --noinput # remove --noinput to create a super user
chmod a+rw sqlite3.db # so apache can write to the db
chmod a+w ./ # so apache can write to the db


echo "Pulling GoProController..."
git submodule update --init

# remove the steps below if you don't want Apache and Upstart

echo "Configuring Apache..."
apt-get install -y apache2 libapache2-mod-wsgi
rm /etc/apache2/sites-enabled/000-default
ln -s /home/GoProApp/GoProApp/apache.conf /etc/apache2/sites-enabled/GoProApp.conf
a2enmod wsgi
service apache2 restart

echo "Configuring Upstart..."
# upstart does not support symlinks
cp /home/GoProApp/GoProApp/upstart.conf /etc/init/gopro-proxy.conf
start gopro-proxy

echo "Good to go!"
