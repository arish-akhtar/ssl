#!/bin/bash

# Function to check SSL expiry date
check_ssl_expiry() {
    local domain=$1
    local expiry_date=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates | grep 'notAfter=' | cut -d'=' -f2)
    local expiry_seconds=$(date -d "$expiry_date" +%s)
    local current_seconds=$(date +%s)
    local remaining_days=$(( ($expiry_seconds - $current_seconds) / 86400 ))
    echo $remaining_days
}

# Iterate through domains provided as arguments
for domain in "$@"
do
    echo "Checking domain: $domain"
    expiry_info=$(check_ssl_expiry $domain)
    remaining_days=$(echo $expiry_info | cut -d ',' -f 1)
    expiry_date=$(echo $expiry_info | cut -d ',' -f 2)
    echo "Remaining days: $remaining_days"
    echo "Expiry Date: $expiry_date"

    if [ $remaining_days -le 30 ]; then
        echo "Sending alert to Slack for domain $domain"
        curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"SSL Expiry Alert\n* Domain: $domain\n* Warning: The SSL certificate for $domain will expire in $remaining_days days on $expiry_date.\"}" $SLACK_WEBHOOK_URL
    fi
done
