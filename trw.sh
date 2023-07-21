#!/bin/sh -e

SLEEPTIME=10

is_processed() {
    grep -q "$1" ./processed_requests.txt
}

while true; do
	kubectl -n teleport exec -i deployment/teleport-cluster-auth -- tctl request ls | grep 'PENDING' &> /dev/null
	if [[ "$?" == 0 ]]; then
		echo "[INFO] PENDING requests found"
		req_str=$(kubectl -n teleport exec -i deployment/teleport-cluster-auth -- tctl request ls | grep 'PENDING' | awk '{ print $1, $2, $3, $NF}')
		req_list=()

		IFS=$'\n' read -d '' -r -a lines <<< "$req_str"
		for line in "${lines[@]}"; do
			echo "-----------------------------"
			items=($line)
			uuid=${items[0]}   # UUID
            reviewer=${items[1]}   # Reviewer
            role=${items[2]}   # Roles
            reason=${items[3]}   # Reason
			if is_processed "$uuid"; then
                echo "Request with UUID $uuid already processed. Skipping..."
            else
                echo "Processing new request with UUID $uuid..."
                # Create a message here to be Slack Payload
				# Even Jira Ticket can be created too
                echo "$uuid" >> processed_requests.txt
            fi
		done
		echo "============================="
		sleep $SLEEPTIME
	else
		echo "[INFO] No Pending Request Observed"
		sleep $SLEEPTIME
	fi
done
