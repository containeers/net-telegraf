# Changelog

All notable changes to the net-telegraf chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-10-14

### Added
- **ExternalName Services for Routers**: New feature to manage network devices (routers, switches, firewalls) as Kubernetes ExternalName services
  - Create DNS aliases for network devices within the cluster
  - Reference routers by name instead of IP addresses
  - Support for labels and annotations for device organization
  - Optional port configuration (ports are for documentation only)
  - New template: `templates/externalname-services.yaml`
  - New configuration section: `routers` in `values.yaml`

### Documentation
- Added `examples/README-router-externalname.md` - Complete guide for using ExternalName services
- Added `examples/values-with-routers.yaml` - Full working example with SNMP monitoring
- Updated main README.md with router management section
- Updated configuration reference table

### Changed
- Chart version bumped from 0.1.0 to 0.2.0
- Enhanced values.yaml with comprehensive router configuration examples

## [0.1.0] - Initial Release

### Added
- Initial chart setup as overlay of InfluxData Telegraf chart v1.8.62
- Prometheus output configuration (port 9273)
- ServiceMonitor support for Prometheus Operator
- Custom scripts support via ConfigMap
- Default system and network monitoring plugins
- Resource limits and requests
- Examples for custom scripts and parsers
- Comprehensive documentation

### Features
- **Prometheus Integration**: Metrics exposed on port 9273
- **Custom Scripts**: Load parser, processor, and collector scripts
- **ServiceMonitor**: Automatic Prometheus Operator integration
- **Network Monitoring**: Pre-configured network monitoring plugins (CPU, disk, net, netstat, etc.)
- **Flexible Configuration**: All Telegraf subchart values can be overridden

### Documentation
- Main README.md with installation and configuration guide
- examples/QUICKSTART.md - 5-minute quick start guide
- examples/README-custom-scripts.md - Custom scripts documentation
- examples/WORKING-EXAMPLE.yaml - Verified working configuration
- examples/values-simple-script.yaml - Simple script example
- examples/values-with-custom-parser.yaml - Advanced parser examples

