# monit stuff
MON_LOGFILE="/dev/null"
#MON_LOGFILE="/var/log/monitor.log"
MON_SERVICE=${0##*/}
MON_ACTION=$1

function monit () {
    service=$1
    action=$2

    # check if we are inside monit
    if [ "$MONIT_SERVICE" ] || [ "$MONIT_EVENT" ]; then
        return
    fi

    # check if monit is installed and running
    if [ ! -x /usr/bin/monit ] || [ ! -f /var/run/monit.pid ]; then
	return
    fi
    if [ ! -f /etc/monit.d/${service}.conf ]; then
	return
    fi

    # if [ -z "$WARNING" ]; then
    #    echo "WARNING: Rather than invoking init scripts through /etc/init.d,"
    #    echo "consider using monit, e.g. monit $MON_ACTION $MON_SERVICE"
    #    WARNING=1
    # fi

    processes=$(sed '/\s*check process /!d; s///;!q' /etc/monit.d/${service}.conf | cut -d ' ' -f 1)
    for process in $(echo $processes); do
	case "$action" in
	    start|sync_start)
		echo "[$(date)] Started monitoring of: $process" >> $MON_LOGFILE
		/usr/bin/monit sync_monitor $process 2>&1 >> $MON_LOGFILE
		;;
	    stop|sync_stop)
		echo "[$(date)] Stopped monitoring of: $process" >> $MON_LOGFILE
		/usr/bin/monit sync_unmonitor $process 2>&1 >> $MON_LOGFILE
		;;                
	esac
    done
}

case "$MON_ACTION" in
    start)
        trap "monit $MON_SERVICE sync_start" EXIT
        ;;
    stop)
        monit $MON_SERVICE sync_stop
        ;;
    condstop)
        if [ -f /var/lock/subsys/$MON_SERVICE ]; then
            monit $MON_SERVICE sync_stop
        fi 
        ;;
    restart)
        monit $MON_SERVICE sync_stop
        trap "monit $MON_SERVICE sync_start" EXIT
        ;;
    condrestart)
        if [ -f /var/lock/subsys/$MON_SERVICE ]; then
            monit $MON_SERVICE sync_stop
            trap "monit $MON_SERVICE sync_start" EXIT
        fi
        ;;
esac


