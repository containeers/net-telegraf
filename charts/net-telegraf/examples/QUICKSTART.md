# Quick Start: Custom Scripts with net-telegraf

This guide gets you up and running with custom scripts in under 5 minutes.

## Step 1: Create Your Values File

Create `my-values.yaml`:

```yaml
# Step 1: Define your custom script
customScripts:
  enabled: true
  scripts:
    hello.sh: |
      #!/bin/bash
      echo "hello_metric,source=custom value=42"

# Step 2: Configure Telegraf
telegraf:
  config:
    agent:
      interval: "10s"
    
    outputs:
      - prometheus_client:
          listen: ":9273"
    
    inputs:
      - exec:
          commands: ["/etc/telegraf/scripts/hello.sh"]
          data_format: "influx"
          interval: "30s"
      - cpu: {}
      - mem: {}
  
  # Step 3: Mount the scripts (REPLACE 'my-release' WITH YOUR ACTUAL RELEASE NAME)
  volumes:
    - name: custom-scripts
      configMap:
        name: my-release-net-telegraf-scripts
        defaultMode: 0755
  
  mountPoints:
    - name: custom-scripts
      mountPath: /etc/telegraf/scripts
      readOnly: true

serviceMonitor:
  enabled: true
```

## Step 2: Add Helm Repo and Update Dependencies

```bash
helm repo add influxdata https://helm.influxdata.com/
helm repo update
helm dependency update charts/net-telegraf
```

## Step 3: Install

```bash
# Important: Use 'my-release' as the release name (or update the configMap name in values)
helm install my-release charts/net-telegraf -f my-values.yaml
```

## Step 4: Verify

```bash
# Check the ConfigMap was created
kubectl get configmap my-release-net-telegraf-scripts

# Check the pod
kubectl get pods -l app.kubernetes.io/name=telegraf

# Verify script is mounted
kubectl exec -it $(kubectl get pod -l app.kubernetes.io/name=telegraf -o jsonpath='{.items[0].metadata.name}') -- ls -la /etc/telegraf/scripts

# Check metrics
kubectl port-forward svc/my-release-telegraf 9273:9273
# In another terminal:
curl http://localhost:9273/metrics | grep hello_metric
```

## Troubleshooting

### ConfigMap name mismatch

If you see errors about ConfigMap not found:

1. Check your release name:
   ```bash
   helm list
   ```

2. Update the ConfigMap name in your values.yaml:
   ```yaml
   telegraf:
     extraVolumes:
       - name: custom-scripts
         configMap:
           name: YOUR-RELEASE-NAME-net-telegraf-scripts  # Update this!
   ```

3. Upgrade:
   ```bash
   helm upgrade my-release charts/net-telegraf -f my-values.yaml
   ```

### Preview ConfigMap name before installing

```bash
helm template my-release charts/net-telegraf -f my-values.yaml | grep "name:.*-scripts"
```

## Next Steps

- See `values-with-custom-parser.yaml` for more advanced examples
- Read `README-custom-scripts.md` for comprehensive documentation
- Check the main README.md for general chart configuration

