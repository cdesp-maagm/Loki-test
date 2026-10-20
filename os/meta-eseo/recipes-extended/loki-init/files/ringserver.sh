#! /bin/sh
# /etc/init.d/loki-seedlink.sh

NAME=ringserver
DESC="Loki SeedLink server"
DAEMON=/usr/bin/$NAME
PIDFILE=/var/run/$NAME.pid
USER=loki
OPTS="/etc/ringserver.conf"

do_start()
{
	start-stop-daemon --start --background --quiet \
        --make-pidfile --pidfile $PIDFILE --chuid $USER \
        --startas /etc/init.d/loki-daemon-wrapper.sh -- native $DAEMON $NAME "$OPTS"
    return $?
}

do_stop()
{
	start-stop-daemon --stop --quiet --retry=5 --pidfile $PIDFILE
    RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2
    rm -f $PIDFILE
	return "$RETVAL"
}

case "$1" in
    start)
        echo "$NAME - Starting $DESC"
        do_start
        exit $?
    ;;
    stop)
        echo "$NAME - Stopping $DESC"
        do_stop
        exit $?
    ;;
    restart)
    	echo "$NAME - Restarting $DESC"
    	do_stop
    	case "$?" in
            0|1)
    		     do_start
    		     exit $?
            ;;
    	    *)
    	 	     # Failed to stop
	             exit 1
    		;;
    	esac
    ;;
    *)
        echo "Usage: $NAME.sh start|stop|restart" >&2
        exit 3
    ;;
esac

exit 0
