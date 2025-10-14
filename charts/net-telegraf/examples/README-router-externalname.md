# Router Monitoring with ExternalName Services

This guide explains how to use Kubernetes ExternalName services to monitor network devices (routers, switches, firewalls) by name instead of IP addresses.

## What are ExternalName Services?

ExternalName services create **DNS CNAME records** that map a service name to an external hostname or IP address.

**Key Points:**
- ✅ Create DNS aliases within the cluster
- ✅ No port mapping or traffic proxying
- ✅ Port configuration is **OPTIONAL** (informational only)
- ✅ Reference routers by name instead of IP addresses

## Why Use This?

1. **Easy Management**: Change router IPs without updating Telegraf config
2. **Organization**: Use labels to group routers by type, location, vendor
3. **Kubernetes-Native**: Manage routers as standard Kubernetes resources
4. **GitOps Ready**: Version control your network inventory

## Quick Start

### 1. Minimal Configuration (No Ports Required)

The simplest configuration only needs `name` and `externalName`:

```yaml
routers:
  enabled: true
  devices:
    - name: router-1
      externalName: 192.168.1.1
    
    - name: router-2
      externalName: router2.company.com
```

### 2. Deploy

```bash
# Create SNMP credentials
kubectl create secret generic snmp-credentials \
  --from-literal=community-string='your-community-string'

# Install the chart
helm install net-telegraf charts/net-telegraf \
  -f examples/values-routers-minimal.yaml
```

### 3. Verify

```bash
# Check that services were created
kubectl get services

# Verify DNS resolution (short name works!)
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup router-1

# Check Telegraf is monitoring
kubectl logs -l app.kubernetes.io/name=telegraf
```

## Port Configuration

**Ports are OPTIONAL** - ExternalName services only create DNS records and don't proxy traffic.

```yaml
# Works without ports
routers:
  devices:
    - name: router-1
      externalName: 192.168.1.1

# Can add ports for documentation
routers:
  devices:
    - name: router-1
      externalName: 192.168.1.1
      ports:
        - name: snmp
          port: 161
          protocol: UDP
```

**Both work identically** - ports are informational only!

## Connection Examples

When using ExternalName services, connect using short names (within same namespace):

### SNMP (Port 161)
```yaml
- snmp:
    agents:
      - "router-1"  # Short name works!
    # SNMP plugin uses port 161 by default
```

### SSH (Port 22)
```yaml
- net_response:
    protocol: "tcp"
    address: "router-1:22"
```

### HTTPS (Port 443)
```yaml
- http_response:
    urls:
      - "https://router-1"
```

### Custom Port
```yaml
- http_response:
    urls:
      - "http://router-1:8080"
```

## Complete Example

See: `values-with-routers.yaml` for a full working example that includes:
- Multiple router definitions with labels
- SNMP and ping monitoring
- Secure credential management
- ServiceMonitor integration

## Configuration Reference

### Router Definition Structure

```yaml
routers:
  enabled: true|false
  devices:
    - name: string              # Required - Service name
      externalName: string      # Required - IP or DNS name
      labels: {}                # Optional - Key-value pairs
      annotations: {}           # Optional - Key-value pairs
      ports: []                 # Optional - Port list (informational)
```

### Minimal Required Fields

Only two fields are required:
```yaml
- name: router-1              # Kubernetes service name
  externalName: 192.168.1.1   # External IP or DNS
```

### Full Configuration Example

```yaml
- name: router-core-1
  externalName: 192.168.1.1
  labels:
    router-type: core
    location: datacenter-1
    vendor: cisco
    priority: critical
  annotations:
    description: "Core router in DC1"
    owner: "network-team@example.com"
  ports:  # OPTIONAL
    - name: snmp
      port: 161
      protocol: UDP
    - name: ssh
      port: 22
      protocol: TCP
```

## Using Labels for Organization

Use labels to organize and filter your network devices:

```yaml
routers:
  devices:
    - name: router-core-1
      externalName: 192.168.1.1
      labels:
        router-type: core          # Device classification
        location: datacenter-1     # Location
        vendor: cisco              # Vendor/Hardware
        priority: critical         # Operational priority
        monitor: "true"            # Enable monitoring
```

Common label patterns: `device-type`, `router-type`, `location`, `vendor`, `model`, `environment`, `priority`, `team`

## DNS Resolution

Kubernetes DNS automatically resolves ExternalName services using `ndots:5` configuration.

### How to Reference Services

**Within the same namespace** (recommended):
```yaml
agents:
  - "router-1"  # Short name works!
```

**From different namespace:**
```yaml
agents:
  - "router-1.default"  # Specify namespace
```

**Fully qualified (optional):**
```yaml
agents:
  - "router-1.default.svc.cluster.local"  # FQDN
```

**All three formats work**, but short names are cleanest when Telegraf is in the same namespace as the router services.

### Why Short Names Work

Kubernetes pods have `ndots:5` in `/etc/resolv.conf`, which automatically searches:
- `<namespace>.svc.cluster.local`
- `svc.cluster.local`
- `cluster.local`

So `router-1` automatically resolves to `router-1.default.svc.cluster.local`

### Testing DNS Resolution

```bash
# Test short name (from same namespace)
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup router-1

# Test FQDN
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup router-1.default.svc.cluster.local
```

## Managing Router Inventory

**Adding a Router:**
```yaml
# 1. Add to values file
routers:
  devices:
    - name: new-router
      externalName: 192.168.10.1

# 2. Add to Telegraf inputs (use short name!)
telegraf:
  config:
    inputs:
      - snmp:
          agents:
            - "new-router"

# 3. Upgrade
helm upgrade net-telegraf charts/net-telegraf -f my-values.yaml
```

**Updating Router IP:**
```yaml
- name: router-1
  externalName: 192.168.1.100  # Just change IP and upgrade
```

**No need to modify Telegraf configuration!**

## Advanced: Dynamic Router Discovery

For advanced use cases, you can discover routers dynamically using the Kubernetes API and custom scripts:

```yaml
customScripts:
  enabled: true
  scripts:
    discover_routers.py: |
      #!/usr/bin/env python3
      import subprocess, json
      result = subprocess.run(['kubectl', 'get', 'services', '-l', 'monitor=true', '-o', 'json'], 
                            capture_output=True, text=True)
      services = json.loads(result.stdout)
      for svc in services.get('items', []):
          name = svc['metadata']['name']
          # Monitor each discovered router
          print(f"Monitoring: {name}.default.svc.cluster.local")
```

This approach allows automatic discovery of routers based on labels.

## Troubleshooting

### Service not resolving

**Check if service exists:**
```bash
kubectl get service router-1
```

**Test DNS resolution:**
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup router-1
```

### Connection timeouts

ExternalName services only provide DNS - network connectivity issues are separate:

**Test connectivity from a pod:**
```bash
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
# Inside the pod:
ping router-1
telnet router-1 161  # SNMP
nc -zv router-1 22   # SSH
```

### Different namespace

If Telegraf and routers are in different namespaces, specify the namespace:

```yaml
# Telegraf in 'monitoring', routers in 'default':
agents:
  - "router-1.default"
```

## Best Practices

1. **Use consistent naming**: `router-{type}-{location}` or `{site}-router-{number}`
2. **Add meaningful labels**: Make filtering and discovery easy
3. **Document with annotations**: Add descriptions, owners, etc.
4. **Version control**: Keep router definitions in Git
5. **Start minimal**: You don't need port configurations
6. **Use secrets**: Store SNMP communities and credentials securely
7. **Monitor the monitors**: Add health checks for Telegraf itself

## Security Considerations

**SNMP Credentials** - Always use Kubernetes Secrets:
```bash
kubectl create secret generic snmp-credentials \
  --from-literal=community-string='your-secret-community'
```

**RBAC** - For dynamic discovery, grant minimal permissions:
```yaml
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
```

## Additional Resources

- [Kubernetes ExternalName Services](https://kubernetes.io/docs/concepts/services-networking/service/#externalname)
- [Telegraf SNMP Input Plugin](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/snmp)
- [Telegraf Ping Input Plugin](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/ping)
- [Example Configurations](./examples/)

## Support

For issues or questions:
1. Check this documentation
2. Review example configurations
3. Test DNS resolution and connectivity
4. Check Telegraf logs: `kubectl logs -l app.kubernetes.io/name=telegraf`

