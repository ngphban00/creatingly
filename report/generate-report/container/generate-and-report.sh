#!/bin/bash

# Run PDF generation
/grafana-reporter -cmd_enable=1 -cmd_dashboard=$DASHBOARD_ID -cmd_apiKey=$API_KEY -ip=$GRAFANA_HOST:$GRAFANA_PORT -cmd_ts from=now-2d -cmd_o report.pdf

# Check if PDF generation was successful
if [ $? -eq 0 ]; then
    # Send email
    envsubst < /etc/ssmtp/ssmtp.conf.template > /etc/ssmtp/ssmtp.conf
    echo "$EMAIL_SUBJECT" | mail -s $EMAIL_TO $SMTP_USER --attach report.pdf
else
    echo "PDF generation failed, email not sent."
    exit 1
fi
