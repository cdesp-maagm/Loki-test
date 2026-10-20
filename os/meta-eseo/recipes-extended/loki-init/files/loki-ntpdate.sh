#! /bin/sh
# /etc/init.d/loki-ntpdate.sh

NAME=loki-ntpdate
DESC="Clock update"

case "$1" in
    start)
        echo "$NAME - Starting $DESC"
        timeout 60 ntpd -g -q
        [ $? -eq 0 ] || echo "$NAME - Failed"
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
