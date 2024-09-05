## Notes
Grafana settings in kube-prometheus-stack have to be updated using variable.
Below is how to update the related variables in deployment of Grafana

(I'm using Gmail!)

```sh
kubectl set env deployment monitoring-stack-grafana GF_SMTP_ENABLED=true GF_SMTP_HOST="smtp.gmail.com:587" GF_SMTP_USER='YOUR_EMAIL_ADDRESS' GF_SMTP_PASSWORD='YOUR_EMAIL_APP_PASSWORD' GF_SMTP_FROM_ADDRESS='YOUR_EMAIL_ADDRESS' GF_SMTP_FROM_NAME="Grafana Admin"
```