#! /bin/sh
# /etc/init.d/loki-fix-filesystem.sh

NAME=loki-fix-filesystem
DESC="Loki storage permission settings"

DATA_DIR=/media/data
CONFIG_DIR=$DATA_DIR/config

LOKI_DIRS=". config config/openvpn log record ringserver"
LOKI_USER_DIRS="home"

case "$1" in
    start)
        echo "$NAME - Starting $DESC"
        # Attribuer les dossiers de LOKI_DIRS à l'utilisateur loki.
        for f in $LOKI_DIRS; do
            mkdir -p $DATA_DIR/$f
            chown -R loki:loki $DATA_DIR/$f
            chmod 755 $DATA_DIR/$f
        done
        # Attribuer les dossiers de LOKI_USER_DIRS à l'utilisateur loki-user.
        for f in $LOKI_USER_DIRS; do
            mkdir -p $DATA_DIR/$f
            chown -R loki-user:loki-user $DATA_DIR/$f
            chmod 755 $DATA_DIR/$f
        done
        # Remplacer le mot de passe de loki-user dans /etc/shadow.
        if [ -e $DATA_DIR/home/.passwd ]; then
            # Supprimer la ligne "loki-user" du fichier /etc/shadow
            sed -i '/^loki-user:/d' /etc/shadow
            # La remplacer par la ligne configurée par l'utilisateur.
            cat $DATA_DIR/home/.passwd >> /etc/shadow
        fi
        # Remplacer le nom de ce système sur le réseau.
        if [ -e $CONFIG_DIR/hostname ]; then
            xargs -a $CONFIG_DIR/hostname hostname
        fi
        # Remplacer le fichier de configuration des interfaces réseau.
        if [ -e $CONFIG_DIR/interfaces ]; then
            cp $CONFIG_DIR/interfaces /etc/network
        fi
        # Remplacer le fichier de configuration des serveurs NTP.
        if [ -e $CONFIG_DIR/ntp.conf ]; then
            cp $CONFIG_DIR/ntp.conf /etc
        fi
        # Donner les droits en écriture sur les LED.
        chmod a+w /sys/class/leds/multi-led-*/*
    ;;
    stop)
        # Empty
    ;;
    *)
        echo "Usage: $NAME.sh start|stop" >&2
        exit 3
    ;;
esac

exit 0
