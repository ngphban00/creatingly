## Quey explain
Below is explaination for each mectrics used in the 2 custom dashboards:
### CPU Usage by container

```sh
sum(rate(container_cpu_usage_seconds_total{namespace="$namespace", pod=~"$pod", image!="", container!="", cluster="$cluster"}[$__rate_interval])) by (container)
```

This query calculates the CPU usage rate for containers within a Kubernetes cluster. Let's break it down:

- **`sum(rate(container_cpu_usage_seconds_total{...}[$__rate_interval]))`**: 
  - `container_cpu_usage_seconds_total`: This metric represents the total amount of CPU time consumed by containers, reported in seconds.
  - `rate(...[$__rate_interval])`: This function computes the per-second rate of change (CPU consumption) for the given time interval (`$__rate_interval`). This is useful to get the rate of CPU usage rather than the absolute total.
  - `sum(...)`: The CPU usage rates are summed across all data points that match the query.

- **`{namespace="$namespace", pod=~"$pod", image!="", container!="", cluster="$cluster"}`**: 
  This is a set of label selectors used to filter the results:
  - `namespace="$namespace"`: Filters the data for containers running in the specified namespace.
  - `pod=~"$pod"`: Uses a regular expression to match the name of the pods, allowing flexibility in the pod name filtering.
  - `image!=""`: Excludes any containers without a specified image.
  - `container!=""`: Excludes any data points that do not have a valid container name.
  - `cluster="$cluster"`: Filters data for containers within the specified cluster.

- **`by (container)`**: Groups the CPU usage data by the container label, so the result shows the CPU usage rate for each container individually.

#### Summary:
This query retrieves and calculates the CPU usage rate for containers in a specific Kubernetes namespace, pod, and cluster, grouping the result by container. It uses a rate calculation to give the per-second CPU consumption and filters out empty or irrelevant data.

### Memory Usage by container

```sh
sum(container_memory_working_set_bytes{namespace="$namespace", pod=~"$pod", image!="", container!="", cluster="$cluster"}) by (container)
```
This query is written in **PromQL** (Prometheus Query Language) and is used to retrieve and sum the memory usage of containers in a Kubernetes cluster.

### Explanation:

- `sum(...) by (container)`:
  - **`sum(...)`**: This sums up the values for each container based on the inner query.
  - **`by (container)`**: This groups the sum by the `container` label, meaning the memory usage is aggregated per container.

- `container_memory_working_set_bytes`:
  - This metric represents the amount of **memory being used** by a container. It excludes cached or inactive memory, giving a clearer view of the actual memory in use.

- `{namespace="$namespace", pod=~"$pod", image!="", container!="", cluster="$cluster"}`:
  - This is a **label filter** to narrow down the data:
    - **`namespace="$namespace"`**: Filters memory metrics for a specific Kubernetes namespace. The `$namespace` is a variable that is usually replaced dynamically.
    - **`pod=~"$pod"`**: Uses a regular expression (`=~`) to filter the memory metrics for pods matching the given pattern `$pod`. This can target one or multiple pods.
    - **`image!=""`**: Ensures the container has an image assigned (i.e., non-empty image).
    - **`container!=""`**: Ensures the container name is not empty.
    - **`cluster="$cluster"`**: Filters by the Kubernetes cluster, where `$cluster` is a variable that gets replaced dynamically.

#### Summary:
This query calculates the sum of **working set memory usage** (actual memory in use) for all containers, grouped by container names, within a specific Kubernetes namespace, pod, and cluster, ensuring that only containers with non-empty names and images are included.

### IOPS by container

```sh
ceil(
    sum by(pod) (
        rate(container_fs_reads_total{
            container!="", 
            device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)", 
            cluster="$cluster", 
            namespace="$namespace", 
            pod=~"$pod"
        }[$__rate_interval]) 
        + 
        rate(container_fs_writes_total{
            container!="", 
            device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)", 
            cluster="$cluster", 
            namespace="$namespace", 
            pod=~"$pod"
        }[$__rate_interval])
    )
)
```

### Components:

1. **`rate(container_fs_reads_total{...}[$__rate_interval])`:**  
   - `container_fs_reads_total`: This metric represents the total number of file system reads in containers.
   - `rate()`: Calculates the per-second average rate of reads over a given time window.
   - `[$__rate_interval]`: This interval (e.g., 5m, 1h) is determined by Grafana's variable `$__rate_interval`, representing the query's time range for computing the rate.

2. **`rate(container_fs_writes_total{...}[$__rate_interval])`:**  
   - `container_fs_writes_total`: This metric represents the total number of file system writes in containers.
   - Like the previous part, it uses `rate()` to calculate the per-second write rate.

3. **Filters for `container_fs_reads_total` and `container_fs_writes_total`:**
   - `container!="":` Excludes empty container labels.
   - `device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"`: Filters device names to focus on block devices (e.g., disks, SSDs, etc.). This regular expression matches various block devices commonly used in Kubernetes environments.
   - `cluster="$cluster"`, `namespace="$namespace"`, `pod=~"$pod"`: These variables are used to filter based on the specific cluster, namespace, and pod (with `$pod` being a regex).

4. **`sum by(pod)`:**  
   Aggregates the total reads and writes by pod, giving the combined I/O metrics (reads + writes) for each pod.

5. **`ceil()`:**  
   The `ceil()` function rounds the result up to the nearest integer. This is useful to ensure that even fractional values are presented as whole numbers.

#### Overall Function:
- The query calculates the total read and write operations per second (I/O) for each container in a Kubernetes cluster, filtered by specific block devices.
- The I/O rate is summed per pod.
- Finally, the result is rounded up to the nearest whole number using `ceil()`.

This query is commonly used to monitor disk activity (I/O) on a per-pod basis in environments where you're running containers and tracking their I/O performance.