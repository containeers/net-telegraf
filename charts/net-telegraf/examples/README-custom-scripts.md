# Using Custom Scripts with net-telegraf

This guide explains how to load custom parser, processor, or collector scripts into your Telegraf deployment.

## Overview

Since the Telegraf deployment is managed by the dependency chart (InfluxData's Telegraf chart), we use a ConfigMap to store custom scripts and mount them into the pods via `volumes` and `mountPoints`.

## Quick Start

### 1. Enable Custom Scripts

Create a values file with your custom scripts:

```yaml
customScripts:
  enabled: true
  mountPath: /etc/telegraf/scripts
  scripts:
    my_parser.py: |
      #!/usr/bin/env python3
      # Your custom parser logic here
      print("custom_metric value=1")
```

### 2. Configure Volume Mounts

Add the volume configuration to mount the scripts:

```yaml
telegraf:
  # ... other telegraf config ...
  
  volumes:
    - name: custom-scripts
      configMap:
        name: RELEASE-NAME-net-telegraf-scripts  # Replace RELEASE-NAME
        defaultMode: 0755
  
  mountPoints:
    - name: custom-scripts
      mountPath: /etc/telegraf/scripts
      readOnly: true
```

**Important:** Replace `RELEASE-NAME` with your actual Helm release name. The ConfigMap name follows the pattern: `<release-name>-net-telegraf-scripts`

### 3. Reference Scripts in Telegraf Config

Use your scripts in Telegraf input plugins:

```yaml
telegraf:
  config:
    inputs:
      - execd:
          command:
            - "/etc/telegraf/scripts/my_parser.py"
          signal: "none"
          restart_delay: "10s"
          data_format: "influx"
```

## Finding Your ConfigMap Name

If you're unsure of the ConfigMap name, use Helm template to preview:

```bash
helm template my-release ./charts/net-telegraf -f my-values.yaml | grep -A 5 "kind: ConfigMap"
```

Or after deployment:

```bash
kubectl get configmaps -n <namespace> | grep scripts
```

## Complete Example

See `values-with-custom-parser.yaml` for a complete working example.

## Supported Script Types

### 1. Parser Scripts (execd input)

Process continuous data streams:

```yaml
customScripts:
  scripts:
    stream_parser.py: |
      #!/usr/bin/env python3
      import sys
      while True:
          # Read and process data
          line = sys.stdin.readline()
          # Output metrics in InfluxDB line protocol
          print(f"measurement,tag=value field=1")
          sys.stdout.flush()
```

### 2. Collector Scripts (exec input)

Collect metrics periodically:

```yaml
customScripts:
  scripts:
    collector.sh: |
      #!/bin/bash
      # Collect metrics and output JSON
      echo '{"metric_name": "value", "field": 123}'
```

### 3. Processor Scripts

Transform metrics in the pipeline:

```yaml
customScripts:
  scripts:
    processor.sh: |
      #!/bin/bash
      while read line; do
        # Transform the metric
        echo "$line,processed=true"
      done
```

## Deployment Steps

1. **Create your values file** with custom scripts and volume configuration

2. **Preview the deployment**:
   ```bash
   helm template my-release ./charts/net-telegraf -f my-values.yaml
   ```

3. **Install or upgrade**:
   ```bash
   helm install my-release ./charts/net-telegraf -f my-values.yaml
   # or
   helm upgrade my-release ./charts/net-telegraf -f my-values.yaml
   ```

4. **Verify the ConfigMap**:
   ```bash
   kubectl get configmap my-release-net-telegraf-scripts -o yaml
   ```

5. **Check if scripts are mounted**:
   ```bash
   kubectl exec -it <pod-name> -- ls -la /etc/telegraf/scripts
   ```

## Troubleshooting

### Scripts not executing

1. **Check script permissions**: Ensure `defaultMode: 0755` is set in volumes
2. **Verify mount**: `kubectl exec -it <pod-name> -- ls -la /etc/telegraf/scripts`
3. **Check shebang**: Ensure scripts have proper shebang (e.g., `#!/usr/bin/env python3`)
4. **Review logs**: `kubectl logs <pod-name>` for Telegraf errors

### ConfigMap not found

1. **Verify ConfigMap exists**: `kubectl get configmap -n <namespace>`
2. **Check ConfigMap name**: It should be `<release-name>-net-telegraf-scripts`
3. **Ensure customScripts.enabled is true**

### Script dependencies missing

If your script requires additional packages:

1. **Use a custom Telegraf image** with dependencies pre-installed:
   ```yaml
   telegraf:
     image:
       repo: "my-registry/telegraf-custom"
       tag: "1.32.0"
   ```

2. **Or install at runtime** (not recommended for production):
   ```yaml
   telegraf:
     env:
       - name: INSTALL_DEPS
         value: "true"
     # Add init container or lifecycle hook
   ```

## Best Practices

1. **Keep scripts simple**: Complex logic should be in external services
2. **Handle errors gracefully**: Scripts should not crash Telegraf
3. **Use appropriate data formats**: InfluxDB line protocol, JSON, etc.
4. **Test scripts locally** before deploying
5. **Monitor script performance**: Slow scripts can impact metric collection
6. **Version your scripts**: Use Git to track changes to your values files

## Example Use Cases

### Custom API Polling

```yaml
customScripts:
  scripts:
    api_poller.py: |
      #!/usr/bin/env python3
      import requests
      import time
      
      while True:
          try:
              resp = requests.get('http://api.example.com/metrics')
              data = resp.json()
              # Convert to InfluxDB line protocol
              print(f"api_metric,source=example value={data['value']}")
              sys.stdout.flush()
          except Exception as e:
              print(f"Error: {e}", file=sys.stderr)
          time.sleep(30)

telegraf:
  config:
    inputs:
      - execd:
          command: ["/etc/telegraf/scripts/api_poller.py"]
          signal: "none"
          restart_delay: "10s"
          data_format: "influx"
```

### Log File Parser

```yaml
customScripts:
  scripts:
    log_parser.sh: |
      #!/bin/bash
      tail -f /var/log/app.log | while read line; do
          if echo "$line" | grep -q "ERROR"; then
              echo "app_errors,level=error count=1"
          fi
      done

telegraf:
  config:
    inputs:
      - execd:
          command: ["/etc/telegraf/scripts/log_parser.sh"]
          signal: "none"
          data_format: "influx"
  
  volumes:
    - name: logs
      hostPath:
        path: /var/log
    # ... custom-scripts volume ...
  
  mountPoints:
    - name: logs
      mountPath: /var/log
      readOnly: true
    # ... custom-scripts mount ...
```

## Additional Resources

- [Telegraf Execd Input Plugin](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/execd)
- [Telegraf Exec Input Plugin](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/exec)
- [InfluxDB Line Protocol](https://docs.influxdata.com/influxdb/latest/reference/syntax/line-protocol/)
- [Telegraf Data Formats](https://github.com/influxdata/telegraf/blob/master/docs/DATA_FORMATS_INPUT.md)

