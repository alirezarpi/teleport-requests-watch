#!/bin/bash -x

SLEEP_SEC=10

JIRA_ENABLE=$JIRA_ENABLE
JIRA_HOST=$JIRA_HOST
JIRA_USER=$JIRA_USER
JIRA_PASS=$JIRA_PASS

SLACK_ENABLE=$SLACK_ENABLE
SLACK_URI=$SLACK_URI
SLACK_CHANNEL=$SLACK_CHANNEL
SLACK_BUTTON_URL=$SLACK_BUTTON_URL

is_processed() {
	grep -q "$1" ./processed_requests.txt 2> /dev/null
}

send_slack_message() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' -d "$message" "$SLACK_URI"
}

create_slack_message() {
    local uuid="$1"
    local requestor="$2"
    local role="$3"
    local reason="$4"

    message=$(cat <<EOF
{
    "channel": "$SLACK_CHANNEL",
    "username": "Teleport Requests",
    "text": "New Teleport Resource Requested",
    "attachments": [
        {
            "text": "Please either Approve or Deny, Regarding the reason",
            "color": "#36a64f",
            "fields": [
                {
                    "title": "UUID",
                    "value": "$uuid"
                },
                {
                    "title": "REQUESTOR",
                    "value": "<@$requestor>"
                },
                {
                    "title": "ROLE",
                    "value": "$role"
                },
                {
                    "title": "reason",
                    "value": $reason
                }
            ],
            "actions": [
                {
                    "name": "req_approval",
                    "text": "Approve/Deny",
                    "type": "button",
                    "style": "primary",
                    "url": "$SLACK_BUTTON_URL?REQ_UUID=$uuid",
                },
            ]
        }
    ]
}
EOF
    )

    send_slack_message "$message"
}

while true; do
	kubectl -n teleport exec -i deployment/teleport-cluster-auth -- tctl request ls | grep 'PENDING' &> /dev/null
	if [ "$?" == 0 ]; then
		echo "[INFO] PENDING requests found"
		req_str=$(kubectl -n teleport exec -i deployment/teleport-cluster-auth -- tctl request ls | grep 'PENDING' | awk '{ print $1, $2, $3, $NF}')
		req_list=()

		IFS=$'\n' read -d '' -r -a lines <<< "$req_str"
		for line in "${lines[@]}"; do
			echo "-----------------------------"
			items=($line)
			uuid=${items[0]}
			requestor=${items[1]}
			role=${items[2]}
			reason=${items[3]}
			if is_processed "$uuid"; then
				echo "Request with UUID $uuid already processed. Skipping..."
			else
				echo "Processing new request with UUID $uuid..."
				if [ "$JIRA_ENABLE" == "true" ]; then
					# Even Jira Ticket can be created too
					echo "jira here"
				fi
				if [ "$SLACK_ENABLE" == "true" ]; then
					# Create a message here to be Slack Payload
					echo "[INFO] Sending Slack Notification for $uuid"
					create_slack_message $uuid $requestor $role $reason
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
