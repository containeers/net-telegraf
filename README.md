# net-telegraf

Helm charts repository for Telegraf with custom configurations and overlays.

## Repository Structure

This repository contains Helm charts for deploying and configuring Telegraf in Kubernetes environments:

```
net-telegraf/
├── charts/
│   └── net-telegraf/          # Telegraf overlay chart with Prometheus output
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       │   ├── _helpers.tpl
│       │   ├── NOTES.txt
│       │   ├── configmap-scripts.yaml
│       │   ├── service-endpoint-devices.yaml
│       │   └── servicemonitor.yaml
│       └── examples/
│           ├── README-custom-scripts.md
│           ├── values-simple-script.yaml
│           └── values-with-custom-parser.yaml
└── README.md                  # This file
```

## Available Charts

### net-telegraf

An overlay Helm chart for Telegraf with Prometheus output, optimized for network monitoring and metrics collection.

**Chart Location:** `charts/net-telegraf/`

This chart is an overlay that wraps the official [InfluxData Telegraf Helm chart](https://github.com/influxdata/helm-charts) version 1.8.62, providing custom configurations and defaults optimized for network monitoring with Prometheus metrics export.

**Key Features:**
- Prometheus integration with metrics exposed on port 9273
- Pre-configured network and system monitoring plugins
- ServiceMonitor support for Prometheus Operator
- Custom script loading via ConfigMaps (parsers, processors, collectors)
- Optimized resource limits and requests

---

## Getting Started

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Prometheus Operator (optional, for ServiceMonitor support)

### Quick Start

All charts in this repository follow a similar installation pattern:

1. Add required Helm repositories
2. Update chart dependencies
3. Install the chart with custom values

See chart-specific sections below for detailed instructions.

## Installation - net-telegraf Chart

### Add the InfluxData Helm repository

```bash
helm repo add influxdata https://helm.influxdata.com/
helm repo update
```

### Install the chart

```bash
# Update dependencies first
helm dependency update charts/net-telegraf

# Install the chart
helm install net-telegraf charts/net-telegraf
```

### Install with custom values

```bash
helm install net-telegraf charts/net-telegraf -f my-values.yaml
```

## Prometheus Integration

### Metrics Endpoint

Telegraf exposes Prometheus metrics on:
- **Port**: 9273
- **Path**: `/metrics`

### ServiceMonitor (for Prometheus Operator)

This chart includes a ServiceMonitor template that can be enabled for automatic Prometheus Operator integration.

#### Enable ServiceMonitor

To enable ServiceMonitor, uncomment and configure the settings in `values.yaml`:

```yaml
serviceMonitor:
  enabled: true
  
  # Additional labels for the ServiceMonitor
  # Important: Match the label selector of your Prometheus instance
  additionalLabels:
    release: prometheus  # For kube-prometheus-stack
  
  # Service port name to scrape
  port: http
  
  # Path to scrape metrics from
  path: /metrics
  
  # Scrape interval
  interval: 30s
  
  # Scrape timeout
  scrapeTimeout: 10s
  
  # HTTP scheme to use for scraping
  scheme: http
```

#### Full ServiceMonitor Configuration Example

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring  # Deploy ServiceMonitor to monitoring namespace
  additionalLabels:
    prometheus: kube-prometheus
    release: prometheus
  annotations:
    description: "Telegraf network metrics"
  port: http
  path: /metrics
  interval: 30s
  scrapeTimeout: 10s
  scheme: http
  
  # Add custom relabelings
  relabelings:
    - sourceLabels: [__meta_kubernetes_pod_node_name]
      targetLabel: node
      action: replace
    - sourceLabels: [__meta_kubernetes_namespace]
      targetLabel: namespace
      action: replace
  
  # Add metric relabelings to filter/transform metrics
  metricRelabelings:
    - sourceLabels: [__name__]
      regex: 'go_.*'
      action: drop  # Drop Go runtime metrics
  
  # Transfer labels from service to scraped metrics
  targetLabels:
    - app
    - environment
```

#### Install with ServiceMonitor Enabled

**Option 1: Using command-line flags**
```bash
helm install net-telegraf charts/net-telegraf \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.additionalLabels.release=prometheus
```

**Option 2: Using a custom values file**

Create a custom values file (e.g., `my-values.yaml`):
```yaml
serviceMonitor:
  enabled: true
  additionalLabels:
    release: prometheus
  port: http
  path: /metrics
  interval: 30s
  scrapeTimeout: 10s
```

Then install:
```bash
helm install net-telegraf charts/net-telegraf -f my-values.yaml
```

#### Verify ServiceMonitor

After installation, verify the ServiceMonitor was created:
```bash
# Check if ServiceMonitor exists
kubectl get servicemonitor -n <namespace>

# View ServiceMonitor details
kubectl describe servicemonitor net-telegraf -n <namespace>

# Check if Prometheus discovered the target
# (requires access to Prometheus UI or API)
```

## Configuration

The chart can be configured by overriding values in the `values.yaml` file. All telegraf subchart values should be prefixed with `telegraf.`

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `telegraf.replicaCount` | Number of Telegraf replicas | `1` |
| `telegraf.image.repo` | Telegraf image repository | `telegraf` |
| `telegraf.image.tag` | Telegraf image tag | `1.32.0` |
| `telegraf.config.agent.interval` | Data collection interval | `10s` |
| `telegraf.config.outputs` | Output plugins configuration | Prometheus client |
| `telegraf.config.inputs` | Input plugins configuration | Various system metrics |
| `telegraf.resources.requests.memory` | Memory request | `256Mi` |
| `telegraf.resources.requests.cpu` | CPU request | `100m` |
| `telegraf.resources.limits.memory` | Memory limit | `512Mi` |
| `telegraf.resources.limits.cpu` | CPU limit | `500m` |
| `telegraf.service.enabled` | Enable service | `true` |
| `telegraf.service.type` | Service type | `ClusterIP` |
| `serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus Operator | `false` |
| `serviceMonitor.interval` | Scrape interval | `30s` |
| `serviceMonitor.scrapeTimeout` | Scrape timeout | `10s` |
| `serviceMonitor.additionalLabels` | Additional labels for ServiceMonitor | `{}` |
| `serviceMonitor.relabelings` | Relabel configs | `[]` |
| `serviceMonitor.metricRelabelings` | Metric relabel configs | `[]` |
| `routers.enabled` | Enable Service + Endpoint for routers | `false` |
| `routers.devices` | List of router/network device definitions | `[]` |
| `routers.devices[].name` | Router service name (required) | - |
| `routers.devices[].ip` | Router IP address (required) | - |
| `routers.devices[].labels` | Labels for the router service | `{}` |
| `routers.devices[].annotations` | Annotations for the router service | `{}` |
| `routers.devices[].ports` | Port definitions (optional, for documentation) | `[]` |
| `customScripts.enabled` | Enable custom scripts ConfigMap | `false` |
| `customScripts.mountPath` | Mount path for scripts in container | `/etc/telegraf/scripts` |
| `customScripts.scripts` | Map of script names to content | `{}` |
| `telegraf.volumes` | Volumes to mount (for scripts) | `[]` |
| `telegraf.mountPoints` | Volume mount points (for scripts) | `[]` |

### Prometheus Output Configuration

The default Prometheus output configuration:

```yaml
telegraf:
  config:
    outputs:
      - prometheus_client:
          listen: ":9273"
          metric_version: 2
          export_timestamp: true
          string_as_label: true
```

**Parameters:**
- `listen`: Address and port to listen on
- `metric_version`: Prometheus metric version (1 or 2)
- `export_timestamp`: Include timestamp in metrics
- `string_as_label`: Convert string fields to labels

### Input Plugins

Default input plugins for system and network monitoring:

- **cpu**: CPU usage statistics
- **disk**: Disk usage and I/O
- **diskio**: Disk I/O statistics
- **mem**: Memory usage
- **net**: Network interface statistics
- **system**: System load and uptime
- **processes**: Process statistics
- **swap**: Swap memory usage
- **netstat**: Network statistics
- **kernel**: Kernel statistics

### Example: Adding Custom Input Plugins

```yaml
telegraf:
  config:
    inputs:
      - ping:
          urls:
            - "8.8.8.8"
            - "1.1.1.1"
          count: 4
          ping_interval: 10.0
      - snmp:
          agents:
            - "192.168.1.1"
          version: 2
          community: "public"
      - http_response:
          urls:
            - "https://example.com"
            - "https://api.example.com/health"
          response_timeout: "5s"
```

### Example: Adjusting Collection Interval

```yaml
telegraf:
  config:
    agent:
      interval: "30s"
      flush_interval: "30s"
```

### Example: Resource Limits

```yaml
telegraf:
  resources:
    requests:
      memory: 512Mi
      cpu: 200m
    limits:
      memory: 1Gi
      cpu: 1000m
```

## Router Management with Service + Endpoint

**NEW**: Monitor network devices (routers, switches, firewalls) using Kubernetes Service + Endpoint approach for consistent behavior with IP addresses.

### Quick Example

Define routers in your values file:

```yaml
routers:
  enabled: true
  devices:
    - name: router-core-1
      ip: 192.168.1.1
      labels:
        router-type: core
        location: datacenter-1
    
    - name: router-edge-2
      ip: 192.168.1.2
      labels:
        router-type: edge
        location: datacenter-2
```

Reference them in Telegraf config by short name:

```yaml
telegraf:
  config:
    inputs:
      - snmp:
          agents:
            - "router-core-1"
            - "router-edge-2"
```

**Benefits:**
- ✅ Use short names like `router-1` (Kubernetes ndots:5 auto-resolves)
- ✅ Works with IP addresses directly
- ✅ Change IPs without updating Telegraf config
- ✅ Organize with labels (type, location, vendor)
- ✅ Kubernetes-native resource management
- ✅ Consistent Service + Endpoint approach for all devices

**Documentation:**
- **`examples/values-with-routers.yaml`** - Complete working example ⭐

## Custom Scripts

Load custom parser, processor, or collector scripts into your Telegraf deployment. This feature enables:
- Custom data parsing from APIs or files
- Metric transformation and processing
- Integration with external data sources
- Custom metric collection logic

### Complete Working Example

Here's a minimal working configuration (see `charts/net-telegraf/examples/WORKING-EXAMPLE.yaml`):

```yaml
# 1. Define your custom script
customScripts:
  enabled: true
  scripts:
    hello.sh: |
      #!/bin/bash
      echo "hello_metric,source=custom value=42"

# 2. Configure Telegraf to use the script
telegraf:
  config:
    inputs:
      - exec:
          commands: ["/etc/telegraf/scripts/hello.sh"]
          data_format: "influx"
  
  # 3. Mount the ConfigMap (replace 'my-release' with your release name)
  volumes:
    - name: custom-scripts
      configMap:
        name: my-release-scripts  # Pattern: <release-name>-scripts
        defaultMode: 0755
  
  mountPoints:
    - name: custom-scripts
      mountPath: /etc/telegraf/scripts
      readOnly: true
```

**Important:** The ConfigMap name follows the pattern `<release-name>-scripts`. For example:
- Release name: `my-telegraf` → ConfigMap: `my-telegraf-scripts`
- Release name: `net-telegraf` → ConfigMap: `net-telegraf-scripts`

### Quick Start

1. **Copy the working example**:
   ```bash
   cp charts/net-telegraf/examples/WORKING-EXAMPLE.yaml my-values.yaml
   ```

2. **Update the ConfigMap name** in `my-values.yaml` to match your release name

3. **Deploy**:
   ```bash
   helm install my-release charts/net-telegraf -f my-values.yaml
   ```

4. **Verify**:
   ```bash
   # Check the script is mounted
   POD=$(kubectl get pod -l app.kubernetes.io/name=telegraf -o jsonpath='{.items[0].metadata.name}')
   kubectl exec -it $POD -- ls -la /etc/telegraf/scripts
   kubectl exec -it $POD -- cat /etc/telegraf/scripts/hello.sh
   
   # Test the script
   kubectl exec -it $POD -- /etc/telegraf/scripts/hello.sh
   ```

### Finding Your ConfigMap Name

Preview before deploying:
```bash
helm template my-release ./charts/net-telegraf -f my-values.yaml | grep "name:.*-scripts"
```

Check after deployment:
```bash
kubectl get configmap | grep scripts
```

### Examples and Documentation

- **`examples/WORKING-EXAMPLE.yaml`** - Verified working configuration ⭐
- **`examples/QUICKSTART.md`** - Step-by-step 5-minute guide
- **`examples/values-simple-script.yaml`** - Minimal example
- **`examples/values-with-custom-parser.yaml`** - Advanced Python & Bash examples
- **`examples/README-custom-scripts.md`** - Complete guide with troubleshooting

### Use Cases

**Custom API Polling:**
```yaml
customScripts:
  scripts:
    api_metrics.py: |
      #!/usr/bin/env python3
      import requests
      data = requests.get('http://api.example.com/metrics').json()
      print(f"api_metric,host=example value={data['count']}")
```

**Log Parsing:**
```yaml
customScripts:
  scripts:
    parse_logs.sh: |
      #!/bin/bash
      tail -f /var/log/app.log | while read line; do
        echo "log_event,app=myapp count=1"
      done
```

**Data Transformation:**
```yaml
customScripts:
  scripts:
    transform.py: |
      #!/usr/bin/env python3
      import sys, json
      for line in sys.stdin:
        data = json.loads(line)
        # Transform and output in InfluxDB line protocol
        print(f"transformed_metric value={data['value']}")
```

## Accessing Metrics

### Port Forward (for testing)

```bash
kubectl port-forward svc/net-telegraf-telegraf 9273:9273
curl http://localhost:9273/metrics
```

### In-Cluster Access

The service is accessible at:
```
http://net-telegraf-telegraf.default.svc.cluster.local:9273/metrics
```

## Dependencies

This chart depends on:
- `telegraf` (version 1.8.62) from https://helm.influxdata.com/

## Updating Dependencies

To update the chart dependencies:

```bash
helm dependency update charts/net-telegraf
```

This will download the telegraf chart into the `charts/` subdirectory.

## Troubleshooting

### Check if metrics are exposed

```bash
kubectl get pods -l app.kubernetes.io/name=telegraf
kubectl port-forward <pod-name> 9273:9273
curl http://localhost:9273/metrics
```

### View Telegraf logs

```bash
kubectl logs -l app.kubernetes.io/name=telegraf -f
```

### Check service endpoints

```bash
kubectl get svc net-telegraf-telegraf
kubectl get endpoints net-telegraf-telegraf
```

## Uninstallation

```bash
helm uninstall net-telegraf
```

---

## Adding New Charts

This repository is structured to support multiple charts. To add a new chart:

1. Create a new directory under `charts/`:
   ```bash
   mkdir -p charts/<new-chart-name>
   ```

2. Create the standard Helm chart structure:
   ```
   charts/<new-chart-name>/
   ├── Chart.yaml
   ├── values.yaml
   ├── templates/
   │   ├── _helpers.tpl
   │   └── ...
   └── README.md
   ```

3. Update this top-level README.md:
   - Add the chart to the "Available Charts" section
   - Add installation and configuration instructions
   - Include any chart-specific documentation

4. Follow Helm best practices:
   - Use semantic versioning
   - Include comprehensive values.yaml with comments
   - Provide example configurations
   - Add NOTES.txt for post-installation instructions

## Repository Maintenance

### Updating Chart Dependencies

For charts with dependencies (like net-telegraf), update them regularly:

```bash
# Update all charts
for chart in charts/*/; do
  helm dependency update "$chart"
done

# Or update a specific chart
helm dependency update charts/net-telegraf
```

### Chart Versioning

When making changes to a chart:
1. Update the `version` field in `Chart.yaml`
2. Follow [Semantic Versioning](https://semver.org/)
3. Document changes in the chart's README

## Support

For issues specific to charts in this repository, please create an issue in this repository.

For issues with upstream charts (e.g., the official Telegraf chart), refer to their respective repositories:
- [InfluxData Helm Charts](https://github.com/influxdata/helm-charts)

## Contributing

Contributions are welcome! To contribute:

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test the charts thoroughly
5. Submit a pull request with a clear description

Please ensure:
- Charts follow Helm best practices
- Documentation is complete and accurate
- Values files include helpful comments
- Templates use proper indentation and formatting

## License

Charts in this repository follow the same licenses as their upstream dependencies where applicable. See individual chart directories for specific license information.
