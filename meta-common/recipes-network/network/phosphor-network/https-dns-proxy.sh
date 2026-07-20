#!/bin/sh
# /usr/bin/https-dns-proxy.sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

test -f /usr/bin/https_dns_proxy || exit 0
test -f /etc/dns.d/dns.conf || exit 0

MODE=`cat /etc/dns.d/dns.conf | grep Mode | awk -F'=' '{ print $2 }'`
AUTO_SERVER=`cat /etc/dns.d/dns.conf | grep ServerName | awk -F'=' '{ print $2 }'`
SERVER_TRAFFIC=`cat /etc/dns.d/dns.conf | grep IpTraffic | awk -F'=' '{ print $2 }'`
DNS_SERVER_1=`cat /etc/dns.d/dns.conf | grep Server1IP | awk -F'=' '{ print $2 }'`
DNS_SERVER_2=`cat /etc/dns.d/dns.conf | grep Server2IP | awk -F'=' '{ print $2 }'`
DNS_SERVER_3=`cat /etc/dns.d/dns.conf | grep Server3IP | awk -F'=' '{ print $2 }'`
RESOLVED_URL=`cat /etc/dns.d/dns.conf | grep ServerURL | awk -F'=' '{ print $2 }'`

Start_Auto_mode_IPv4() {
	
	#Route all DNS packet to https-dns-proxy, except daemon itself
	iptables -t nat -A OUTPUT -p tcp --dport 53 -m owner --uid-owner nobody -j ACCEPT
	iptables -t nat -A OUTPUT -p udp --dport 53 -m owner --uid-owner nobody -j ACCEPT
	iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5053
	iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5053
	if [ "$AUTO_SERVER" == "Google" ]
	then
		https_dns_proxy -u nobody -g nogroup -d -b 8.8.8.8,8.8.4.4 -a 127.0.0.1 -4 -r "https://dns.google/dns-query"
	elif [ "$AUTO_SERVER" == "Cloudflare" ]
	then
		https_dns_proxy -u nobody -g nogroup -d -b 1.1.1.1,1.0.0.1 -a 127.0.0.1 -4 -r "https://cloudflare-dns.com/dns-query"
	elif [ "$AUTO_SERVER" == "OpenDNS" ]
	then
		https_dns_proxy -u nobody -g nogroup -d -b 208.67.222.222,208.67.220.220 -a 127.0.0.1 -4 -r "https://doh.opendns.com/dns-query"
	fi
}

Start_Auto_mode_IPv6() {
	ip6tables -t nat -A OUTPUT -p tcp --dport 53 -m owner --uid-owner nobody -j ACCEPT
	ip6tables -t nat -A OUTPUT -p udp --dport 53 -m owner --uid-owner nobody -j ACCEPT
	ip6tables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5053
	ip6tables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5053
	if [ "$AUTO_SERVER" == "Google" ]
	then
		https_dns_proxy -u nobody -g nogroup -d -b 2001:4860:4860::8888,2001:4860:4860::8844 -a ::1 -r "https://dns.google/dns-query"
	elif [ "$AUTO_SERVER" == "Cloudflare" ]
	then
		https_dns_proxy -u nobody -g nogroup -d -b 2606:4700:4700::1111,2606:4700:4700::1001 -a ::1 -r "https://cloudflare-dns.com/dns-query"
	elif [ "$AUTO_SERVER" == "OpenDNS" ]
	then
		https_dns_proxy -u nobody -g nogroup -d -b 2620:119:35::35,2620:119:53::53 -a ::1 -r "https://doh.opendns.com/dns-query"
	fi
}

Start_Manual_mode() {
	if [ -z "$DNS_SERVER_1" ] && [ -z "$DNS_SERVER_2" ] && [ -z "$DNS_SERVER_3" ]
	then
		echo -n "No available DNS Server"
		exit 0;
	fi
	if [ -z "$RESOLVED_URL" ] 
	then
		echo -n "No available Resolved_URL"
		exit 0;
	fi
		
	if [ -n "$DNS_SERVER_1" ]
	then
		if [ "$DNS_SERVER_1" != "0.0.0.0" ] && [ "$DNS_SERVER_1" != "${DNS_SERVER_1#*[0-9].[0-9]}" ]
		then
  			IPv4_SERVER="$DNS_SERVER_1"
		elif [ "$DNS_SERVER_1" != "::" ] && [ "$DNS_SERVER_1" != "${DNS_SERVER_1#*:[0-9a-fA-F]}" ]
		then 
  			IPv6_SERVER="$DNS_SERVER_1"
		fi
	fi
	
	if [ -n "$DNS_SERVER_2" ]
	then
		if [ "$DNS_SERVER_2" != "0.0.0.0" ] && [ "$DNS_SERVER_2" != "${DNS_SERVER_2#*[0-9].[0-9]}" ]
		then
			if [ -n "$IPv4_SERVER" ]
			then
  				IPv4_SERVER=$IPv4_SERVER,$DNS_SERVER_2
  			else
  				IPv4_SERVER=$DNS_SERVER_2
  			fi
		elif [ "$DNS_SERVER_2" != "::" ] && [ "$DNS_SERVER_2" != "${DNS_SERVER_2#*:[0-9a-fA-F]}" ]
		then
			if [ -n "$IPv6_SERVER" ]
			then
  				IPv6_SERVER=$IPv6_SERVER,$DNS_SERVER_2
  			else
  				IPv6_SERVER=$DNS_SERVER_2
  			fi  			
		fi
	fi
	
	if [ -n "$DNS_SERVER_3" ]
	then
		if [ "$DNS_SERVER_3" != "0.0.0.0" ] && [ "$DNS_SERVER_3" != "${DNS_SERVER_3#*[0-9].[0-9]}" ]
		then
			if [ -n "$IPv4_SERVER" ]
			then
  				IPv4_SERVER=$IPv4_SERVER,$DNS_SERVER_3
  			else
  				IPv4_SERVER=$DNS_SERVER_3
  			fi
		elif [ "$DNS_SERVER_3" != "::" ] && [ "$DNS_SERVER_3" != "${DNS_SERVER_3#*:[0-9a-fA-F]}" ]
		then
			if [ -n "$IPv6_SERVER" ]
			then
  				IPv6_SERVER=$IPv6_SERVER,$DNS_SERVER_3
  			else
  				IPv6_SERVER=$DNS_SERVER_3
  			fi
		fi
	fi
	
	if [ -n "$IPv6_SERVER" ] && [ -n "$RESOLVED_URL" ]
	then
		ip6tables -t nat -A OUTPUT -p tcp --dport 53 -m owner --uid-owner nobody -j ACCEPT
		ip6tables -t nat -A OUTPUT -p udp --dport 53 -m owner --uid-owner nobody -j ACCEPT
		ip6tables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5053
		ip6tables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5053
		https_dns_proxy -u nobody -g nogroup -d -b $IPv6_SERVER -a ::1 -r "$RESOLVED_URL"
	fi
	if [ -n "$IPv4_SERVER" ] && [ -n "$RESOLVED_URL" ]
	then
		iptables -t nat -A OUTPUT -p tcp --dport 53 -m owner --uid-owner nobody -j ACCEPT
		iptables -t nat -A OUTPUT -p udp --dport 53 -m owner --uid-owner nobody -j ACCEPT
		iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5053
		iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5053
		https_dns_proxy -u nobody -g nogroup -d -b $IPv4_SERVER -a 127.0.0.1 -4 -r "$RESOLVED_URL"
	fi		
}

case "$1" in
	start)
		echo -n "Starting https-dns-proxy service :"
		if [ "$MODE" == "Disable" ]
		then
			echo -n "Disable mode"
			exit 0
		elif [ "$MODE" == "Auto" ]
		then
			echo "Auto mode"
			if [ "$SERVER_TRAFFIC" == "IPv4" ]
			then
				Start_Auto_mode_IPv4		
			elif [ "$SERVER_TRAFFIC" == "IPv6" ]
			then
				Start_Auto_mode_IPv6
			elif [ "$SERVER_TRAFFIC" == "Both" ]
			then
				Start_Auto_mode_IPv4
				Start_Auto_mode_IPv6
			fi
		elif [ "$MODE" == "Manual" ]
		then
			echo "Manual mode"
			Start_Manual_mode
		fi

		;;
	stop)
		echo -n "Stopping https-dns-proxy service"
		#Flush all nat route rule
		iptables -t nat -F
		ip6tables -t nat -F
		killall -1 https_dns_proxy
		echo "."
		;;
	reload)
		$0 restart
		;;
	force-reload)
		$0 restart
		;;
	restart)
		$0 stop && sleep 2 && $0 start
		echo "."
		;;
	*)
		echo "Usage: /usr/bin/https_dns_proxy {start|stop|reload|restart|force-reload}"
		exit 1
esac

exit 0
