## Max IOPS per pod
![Max IOPS per pod](/images/max-iops-per-pod.png)

You can import the dashboard's JSON into Grafana. Check it out in the same folder of this README.

This dashboard is split into 2 panel for read/write IOPS counts

## Metric explain
Since the calculation is similar to both, I would just explain one for read IOPS.
__Read IOPS__

```sh
max_over_time(
  sum(rate(container_fs_reads_bytes_total{job="kubelet", container!="POD"}[5m]) / 4096) by (pod)
  [2d:]
)
```

Breakdown
Breakdown of the Query:

1. rate(container_fs_reads_bytes_total{job="kubelet", container!="POD"}[5m]) / 4096:
- This part of the query remains the same as before. It calculates the per-second read IOPS for each pod.

2. sum(... ) by (pod):

- The sum function groups the IOPS values by pod, providing the total read IOPS for each pod.

3. max_over_time(... [2d:]):

- max_over_time(... [2d:]): This function calculates the maximum value of the input query over the past two days (2d).
- The [2d:] syntax tells Prometheus to consider all data points within the last 2 days for the calculation.
- The result will give you the maximum read IOPS observed for each pod during the last two days.