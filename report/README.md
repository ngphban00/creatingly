## How reporting works
![How reporting works](/images/grafana_dashboard_report.png)
- A k8s cronjob (pdf-and-email-cronjob) periodically generates images from dashboard's URL
- A task in that cronjob convert downloaded images to pdf format
- Another task in that cronjob attaches the pdf report then sends it to the relevant recipient

## Reporting components
- Grafana container
- Grafana image rendering container
- Cronjob for dashboard (generate pdf and email)

## Configurations
### Deployment for Grafana image renderer
See in sub-folder __image-renderer__
```sh
.
├── pod.yaml
└── svc.yaml

0 directories, 2 files
```
Deploy it
```sh
kubectl -f image-renderer/
```
### Configs in Grafa instance
```sh
kubectl env deployment monitoring-stack-grafana GF_RENDERING_SERVER_URL='http://renderer:8081/render' \
GF_RENDERING_CALLBACK_URL='http://monitoring-stack-grafana/' \
GF_LOG_FILTERS='rendering:debug'
```
### Cronjob for reporting
See in sub-folder __generate-report__
```sh
generate-report/
├── container
│   ├── Dockerfile
│   ├── generate-and-report.sh
│   ├── grafana-reporter
│   └── ssmtp.conf.template
└── dashboard-report.yaml

1 directory, 5 files
```
Those files in __container__ sub-folder are used to build the genering-report docker image. I have pushed it in public repo (baoannguyen/grafana-dashboard-report)
To deploy the cronjob
```sh
kubectl apply -f dashboard-report.yaml
```
This cronjob is triggered in each 2 days. Once it gets triggered, the specified dashboard will be rendered from Grafana, gets converted to pdf then sent as attachment in receiver's email.

See the sample __report.pdf__ in the same folder of above template.
It is attached in receiver's email like below:
![Email attached](/images/email_attachment.png)
