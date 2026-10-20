#! /bin/sh
# Usage: loki-daemon-wrapper type script name opts

FIFO=/tmp/$3-fifo
[ ! -e $FIFO ] && mkfifo $FIFO

terminate()
{
    kill $P
    kill $L
}

trap terminate TERM

case "$1" in
    python)
        python3 -u $2 $4 &> $FIFO &
    ;;
    native)
        $2 $4 &> $FIFO &
    ;;
    *)
        echo "Invalid daemon type: $1"
        exit 3
    ;;
esac
P=$!

/usr/bin/logger -t $3 < $FIFO &
L=$!

wait $P
