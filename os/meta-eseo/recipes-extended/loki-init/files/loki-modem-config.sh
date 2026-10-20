#! /bin/sh
# /etc/init.d/loki-modem-config.sh

NAME=loki-modem-config
DESC="Loki modem configuration utility"
DAEMON=/usr/bin/$NAME
JSON=/media/data/config/loki-modem-config.json
OPTS="--load $JSON"

case "$1" in
    start)
        echo "$NAME - Starting $DESC"
        if [ -e $JSON ]; then
            $DAEMON $OPTS 2>&1 | /usr/bin/logger -t $NAME
        else
            echo "$NAME - Warning: Missing configuration file: $JSON"
        fi
    ;;
    stop)
        # TODO
        # /path/to/your/shutdown/scripts
    ;;
    *)
        echo "Usage: $NAME.sh start|stop" >&2
        exit 3
    ;;
esac

exit 0
