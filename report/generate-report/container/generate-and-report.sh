#!/bin/bash

# Function to generate PDF report
generate_pdf_report() {
    local dashboard_id=$1
    local output_file="report_$dashboard_id.pdf"

    echo "Generating PDF report for dashboard: $dashboard_id"
    /grafana-reporter \
        -cmd_enable=1 \
        -grid-layout=1 \
        -cmd_dashboard=$dashboard_id \
        -cmd_apiKey=$API_KEY \
        -ip="$GRAFANA_HOST:$GRAFANA_PORT" \
        -cmd_ts from=now-2d \
        -cmd_o $output_file

    if [ $? -ne 0 ]; then
        echo "Failed to generate PDF for dashboard: $dashboard_id"
        return 1
    fi

    echo "PDF report generated: $output_file"
    return 0
}

# Function to send email with generated PDFs as attachments
send_email() {
    echo "Sending email to: $EMAIL_TO"
    envsubst < /etc/ssmtp/ssmtp.conf.template > /etc/ssmtp/ssmtp.conf

    echo "$EMAIL_SUBJECT" | mail -s "$EMAIL_SUBJECT" $EMAIL_TO \
        --attach "report_$POD_DASHBOARD_ID.pdf" \
        --attach "report_$PVC_DASHBOARD_ID.pdf"

    if [ $? -ne 0 ]; then
        echo "Failed to send email."
        return 1
    fi

    echo "Email sent successfully."
    return 0
}

# Main execution
echo "Starting PDF generation and email process..."

generate_pdf_report $POD_DASHBOARD_ID
pod_status=$?

generate_pdf_report $PVC_DASHBOARD_ID
pvc_status=$?

if [ $pod_status -eq 0 ] && [ $pvc_status -eq 0 ]; then
    send_email
else
    echo "PDF generation failed, email not sent."
    exit 1
fi

echo "Process completed."
