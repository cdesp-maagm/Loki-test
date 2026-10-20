#! /bin/sh

passwd loki-user
sudo grep '^loki-user:' /etc/shadow > /media/data/home/.passwd
chmod 600 /media/data/home/.passwd
sync
