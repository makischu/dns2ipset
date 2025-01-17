#!/bin/bash
modprobe br_netfilter
echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables
#echo "1" > /proc/sys/net/bridge/bridge-nf-call-ip6tables
ipset create dnsa iphash
iptables-restore < /etc/network/iptables.firewall >> /var/log/firewallup.sh.log 2>&1
#ip6tables-restore < /etc/network/ip6tables.firewall >> /var/log/firewallup.sh.log 2>&1
echo "$(date): ip[6]tables restored" >> /var/log/firewallup.sh.log
