#! /bin/sh
# /etc/init.d/loki-record.sh

NAME=loki-record
DESC="Loki Recording Daemon"
DAEMON=/usr/bin/$NAME
PIDFILE=/var/run/$NAME.pid
READYFILE=/var/run/$NAME.ready
USER=loki
JSON=/media/data/config/loki-system-config.json
SETUP=/media/data/config/loki-record-setup.sh
OPTS="--load $JSON"

ready() {
    [ $(loki-record-config autostart) == True -o -e $READYFILE ]
    RES=$?
    touch $READYFILE
    return $RES
}

do_start()
{
    if [ -x $SETUP ]; then
        $SETUP
    fi
    if [ -e $JSON ]; then
        if ready && [ "$(loki-record-config record_enable)" == True ]; then
        	/sbin/start-stop-daemon --start --background --quiet \
                --make-pidfile --pidfile $PIDFILE --chuid $USER \
                --startas /etc/init.d/loki-daemon-wrapper.sh -- python $DAEMON $NAME "$OPTS"
            return $?
        else
            echo "$NAME - Cancelled (autostart disabled)"
            return 0
        fi
    else
        echo "$NAME - Error: Missing configuration file: $JSON"
        return 2
    fi
}

do_stop()
{
	/sbin/start-stop-daemon --stop --quiet --retry=5 --pidfile $PIDFILE
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
