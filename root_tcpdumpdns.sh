#!/bin/bash
#makischu 2025
#provided as-is
# demonstrates usage of tcpdump on a transparent bridge to snoop dns responses
# and add gained IP addresses to an ipset for usage in iptables.

longcommand="tcpdump -i br0 -nn -l --immediate-mode  udp port 53"
#longcommand="cat test.txt" #for devolopment/test only.

handleA() {
	IP="$1"
	#ignore piholes dummy answer
        if [[ $IP == "0.0.0.0" ]]; then 
                ignoring=1
        else
		#add ip it to the ipset used by iptables to allow traffic to.
                action=$(ipset add dnsa $IP 2>&1)
		if [[ $action == *"Element cannot be added to the set: it's already added"* ]]; then
			#known case, no need to report
			ignoring=1
			#echo "already added. its ok."
		elif [[ $action == *"The set with the given name does not exist"* ]]; then
			echo "set does not exist. bad setup."
		else
			#on success: no need to report.
			if [ ${#action} -gt 0 ]; then
				echo $action
			fi
		fi
	fi
}

handleAcandidate() {
	#ingore preceding space
	cand=$(echo "$2" | xargs)
	#filter for "A x.y.z.a" 
	addr=$(echo "$cand" | sed -n -E 's/^A ([0-9.]*)$/\1/p')
	#in case of match go on
	if [ ${#addr} -gt 6 ]; then
		handleA $addr
	fi
}


handleLine() {
	#save raw input for potential postprocessing or bugfixing.
	#mytime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")  not used any more as tcpdump already includes timestamp.
	mydate=$(date -u +"%Y%m%d")
	line=$1
	echo "$line" >> /var/log/dnsa/dnslog$mydate.txt
}

$longcommand |
  while IFS= read -r line
  do
        IP=$(echo "$line" | cut -d' ' -f2)
    if [[ $IP == "IP" ]]; then
        REST=$(echo "$line" | cut -d' ' -f8- | cut -d'(' -f1)
        handleLine "$line"
	#handle each item of comma separated list separately:
	mapfile <<<"$REST" -td \, -c 1 -C handleAcandidate
    fi
  done
