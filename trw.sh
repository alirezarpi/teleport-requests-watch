#!/bin/sh 

SLEEP_SEC=10

JIRA_ENABLE=$JIRA_ENABLE
JIRA_HOST=$JIRA_HOST
JIRA_USER=$JIRA_USER
JIRA_PASS=$JIRA_PASS

SLACK_ENABLE=$JIRA_ENABLE
SLACK_URI=$JIRA_URI
SLACK_CHANNEL=$JIRA_CHANNEL

is_processed() {
	grep -q "$1" ./processed_requests.txt 2> /dev/null
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
			uuid=${items[0]}
			reviewer=${items[1]}
			role=${items[2]}
			reason=${items[3]}
			if is_processed "$uuid"; then
				echo "Request with UUID $uuid already processed. Skipping..."
			else
				echo "Processing new request with UUID $uuid..."
				if [[ "$JIRA_ENABLE" == "true" ]]; then
					# Even Jira Ticket can be created too
					echo "jira here"
				fi
				if [[ "$SLACK_ENABLE" == "true" ]]; then
					# Create a message here to be Slack Payload
					echo "slack here"

				fi
				echo "$uuid" >> processed_requests.txt
			fi
		done
		echo "============================="
		sleep $SLEEP_SEC
	else
		echo "[INFO] No Pending Request Observed"
		echo "----------------------------------"
		sleep $SLEEP_SEC
	fi
done
