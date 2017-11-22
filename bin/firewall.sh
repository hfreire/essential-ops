#!/bin/sh
#
# @name firewall.sh
# @version 0.1.2
# @args $1 = action (up/down)
# @description
# @author Hugo Freire <hugo.freire@t-creator.pt>

IPTABLES=$(which iptables)
WAN_IF=eth0

do_start() {
	$IPTABLES -P INPUT DROP
	$IPTABLES -P OUTPUT ACCEPT
	$IPTABLES -P FORWARD DROP
	
	$IPTABLES -N ssh_wan
	$IPTABLES -A ssh_wan -m recent --set --name ssh
	$IPTABLES -A ssh_wan -m recent --update --seconds 60 --hitcount 3 --name ssh -j DROP 
	$IPTABLES -A ssh_wan -m limit --limit 20/minute --limit-burst 10 -j ACCEPT
	
	$IPTABLES -N input_wan
	$IPTABLES -A input_wan -p icmp -m icmp --icmp-type 8 -j ACCEPT
	$IPTABLES -A input_wan -p tcp --dport 22 -j ssh_wan
	$IPTABLES -A input_wan -p tcp --dport 80 -j ACCEPT
	$IPTABLES -A input_wan -j DROP
	
	$IPTABLES -N input
	$IPTABLES -A input -p tcp ! --syn -j DROP
	$IPTABLES -A input -i eth0 -j input_wan
	$IPTABLES -A input -j DROP
	
	$IPTABLES -A INPUT -i lo -j ACCEPT
	$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$IPTABLES -A INPUT -m state --state NEW -j input
	$IPTABLES -A INPUT -j DROP
}

do_stop() {

	$IPTABLES -P INPUT ACCEPT
	$IPTABLES -P FORWARD ACCEPT
	$IPTABLES -P OUTPUT ACCEPT
	$IPTABLES -F
	$IPTABLES -X
	
	$IPTABLES -t nat -P PREROUTING ACCEPT
	$IPTABLES -t nat -P POSTROUTING ACCEPT
	$IPTABLES -t nat -P OUTPUT ACCEPT
	$IPTABLES -t nat -F
	$IPTABLES -t nat -X
	
	$IPTABLES -t mangle -P PREROUTING ACCEPT
	$IPTABLES -t mangle -P POSTROUTING ACCEPT
	$IPTABLES -t mangle -P INPUT ACCEPT
	$IPTABLES -t mangle -P FORWARD ACCEPT
	$IPTABLES -t mangle -P OUTPUT ACCEPT
	$IPTABLES -t mangle -F
	$IPTABLES -t mangle -X
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
        echo "Usage: firewall.sh [start|stop]" >&2
        exit 1
        ;;
esac
