#!/bin/sh
#
# @name qos.sh
# @version 0.1.1
# @args $1 = action (up/down)
# @description
# @author Hugo Freire <hugo.freire@t-creator.pt>

TC=$(which tc)
IPTABLES=$(which iptables)
WAN_IF=eth0
WAN_BW=10mbit

do_start() {
	$TC qdisc add dev $WAN_IF root handle 1:0 htb default 40
	$TC class add dev $WAN_IF parent 1:0 classid 1:1 htb rate $WAN_BW
	$TC class add dev $WAN_IF parent 1:1 classid 1:10 htb rate 1mbit ceil 3mbit prio 0
	$TC class add dev $WAN_IF parent 1:1 classid 1:20 htb rate 5mbit ceil 5mbit prio 1
	$TC class add dev $WAN_IF parent 1:1 classid 1:30 htb rate 3mbit ceil 5mbit prio 2
	$TC class add dev $WAN_IF parent 1:1 classid 1:40 htb rate 3mbit ceil 5mbit prio 3
	
	$IPTABLES -t mangle -A OUTPUT -m length --length 0:60 -j CLASSIFY --set-class 1:10
	$IPTABLES -t mangle -A OUTPUT -p icmp -m icmp --icmp-type 8 -j CLASSIFY --set-class 1:10
	$IPTABLES -t mangle -A OUTPUT -o $WAN_IF -p tcp -m multiport --ports 22,25 -j CLASSIFY --set-class 1:20
	$IPTABLES -t mangle -A OUTPUT -o $WAN_IF -p tcp --sport 80 -j CLASSIFY --set-class 1:30
}

do_stop() {
	$IPTABLES -t mangle -P PREROUTING ACCEPT
	$IPTABLES -t mangle -P POSTROUTING ACCEPT
	$IPTABLES -t mangle -P INPUT ACCEPT
	$IPTABLES -t mangle -P FORWARD ACCEPT
	$IPTABLES -t mangle -P OUTPUT ACCEPT
	$IPTABLES -t mangle -F
	$IPTABLES -t mangle -X
	
	$TC qdisc del dev $WAN_IF root
}

case "$1" in
        start)
        	do_start
        ;;
        stop)
        	do_stop
        ;;
        restart)
        	do_stop
        	do_start
        ;;        
        *)
        echo "Usage: qos.sh [start|stop]" >&2
        exit 1
        ;;
esac
