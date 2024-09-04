[![How reporting works]((../images/grafana_dashboard_report.png)
- A k8s cronjob (pdf-and-email-cronjob) periodically generates images from dashboard's URL
- A task in that cronjob convert downloaded images to pdf format
- Another task in that cronjob attaches the pdf report then sends it to the relevant recipient

## Reporting components
- Grafana container
- Grafana image rendering container
- Cronjob for dashboard (generate pdf and email)

## Configurations
### Deploymwent for Grafana image renderer
See in sub-folder __image-renderer__
Deploy it
```sh
kubectl -f image-renderer/
```
### Configs in Grafa instance
```sh
kubectl env deployment
```
### Cronjob for reporting
see in sub-folder __generate-report__
```sh
```
