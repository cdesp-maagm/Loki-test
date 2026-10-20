#! /bin/sh
# /etc/init.d/loki-macaddr.sh

NAME=loki-macaddr
DESC="Loki hardware address setting from EEPROM"

EEPROM_DEVICE="/sys/bus/i2c/devices/0-0050/eeprom"
EEPROM_TIMEOUT=5s

case "$1" in
    start)
        echo "$NAME - Starting $DESC"

        mount /dev/mmcblk0p1 /mnt
        if [ "$(grep ethaddr /mnt/uEnv.txt)" == "" ]; then
            EEPROM_DATA=$(timeout $EEPROM_TIMEOUT cat $EEPROM_DEVICE)
            EEPROM_STATUS=$?
            if [ $EEPROM_STATUS -ne 0 ]; then
                echo "$NAME - Failed to read from EEPROM"
                exit $EEPROM_STATUS
            fi

            # Lire 6 octets dans l'EEPROM à partir de l'adresse 0xFA
            # les convertir en hexadécimal, un octet à la fois,
            # éliminer les espaces en début et fin, remplacer les espaces entre
            # les octets par des ":".
            MAC=$(echo $EEPROM_DATA | od --skip-bytes=250 --read-bytes=6 --address-radix=n --format=x1 | sed -e 's/^\s*//' -e 's/\s*$//' -e 's/ /:/g')

            # Ajouter l'adresse MAC dans le fichier de démarrage du bootloader uEnv.txt.
            echo "$NAME: Setting MAC address $MAC in bootloader configuration file. Will take effect after reboot"
            echo "ethaddr=$MAC" >> /mnt/uEnv.txt
        fi
        umount /mnt
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
