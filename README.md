# 🛡️ NAS MasterX v1.1 - NAS Monitoring & Repair System for Fedora Server
**Fedora Bash License AI-Ready | Smart Performance Monitoring | Auto-Upgrade**

![Version](https://img.shields.io/badge/version-1.1-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 📖 Overview
NAS MasterX v1.1 is an intelligent, auto-detecting NAS monitoring system that provides enterprise-grade monitoring for home and small business users. It automatically detects your NAS configuration and creates custom monitoring scripts tailored to your specific setup.

### 🎯 What's New in v1.1
- ✅ **Auto-Upgrade System** - Seamlessly upgrades from previous versions
- ✅ **Smart Performance Monitoring** - Read/write speed benchmarking with thresholds
- ✅ **File Tree Recording** - Preserves directory structure for data recovery
- ✅ **Enhanced Log Management** - Automatic cleanup with intelligent viewing
- ✅ **Comprehensive Stress Testing** - Validates installation thoroughly
- ✅ **Improved Diagnostics** - Better hardware detection and reporting

## 🚀 Quick Start

### Prerequisites
- Fedora Server, RHEL, CentOS, or compatible Linux distribution
- A mounted NAS/storage volume
- sudo privileges
- Minimum 200MB free space on NAS for performance tests

### Installation (One Command)
```bash
# Download and run the installer
sudo mkdir -p /opt/media_stack/NAS_MasterX
cd /opt/media_stack/NAS_MasterX
sudo curl -L -O https://github.com/SkullEnemyX/NAS-MasterX/releases/download/Installer/nas_masterx_installer.sh
sudo chmod +x nas_masterx_installer.sh
./nas_masterx_installer.sh
```

### 🆕 Auto-Upgrade Feature
If you have a previous version installed, NAS MasterX v1.1 will:
- Auto-detect existing installation
- Safely uninstall previous version
- Preserve your configuration
- Install fresh v1.1 with all new features

## 🏗️ How It Works

### Architecture Overview
```
NAS MasterX System v1.1
├── 🔄 Auto-Upgrade Engine
│   ├── Detects existing installations
│   ├── Safe uninstallation process
│   └── Configuration preservation
├── 🔍 Enhanced Auto-Detection
│   ├── Scans for largest storage volume
│   ├── Checks common mount points
│   ├── Detects LVM configurations
│   └── Identifies filesystem types
├── ⚡ Performance Monitoring
│   ├── Read/write speed benchmarking
│   ├── Automatic threshold detection
│   └── Disk health recommendations
├── 🌲 File Tree Recording
│   ├── Directory structure preservation
│   ├── Recovery-ready documentation
│   └── Tree-based or find-based generation
├── 🧹 Smart Log Management
│   ├── 7-day auto-cleanup
│   ├── Enhanced log viewer
│   └── Intelligent preview system
├── 🕵️ Monitoring Scripts
│   ├── Health monitoring (filesystem, hardware, performance)
│   └── AI-ready JSON reporting
├── ⚡ Automated System
│   ├── Systemd service (runs hourly)
│   └── Comprehensive logging
└── 🛠️ Diagnostic Tools
    ├── Interactive menu system
    └── AI report generation
```

### Performance Thresholds
| Metric | Warning Threshold | Critical Threshold | Action |
|--------|-------------------|-------------------|--------|
| Read Speed | < 50 MB/s | < 20 MB/s | Check disk health |
| Write Speed | < 30 MB/s | < 10 MB/s | Consider replacement |
| Disk Usage | > 80% | > 90% | Clean up data |
| Inode Usage | > 80% | > 90% | Remove small files |

## 📁 Enhanced System Structure

```
/opt/media_stack/NAS_MasterX/
├── 📄 nas_masterx_installer.sh     # Main installer v1.1
├── 📖 README.md                    # This enhanced manual
├── 🛠️ scripts/                     # Generated monitoring scripts
│   ├── nas_health_monitor.sh       # Enhanced health monitor
│   └── nas_diagnostic_tool.sh      # Interactive diagnostics v1.1
├── 📊 logs/                        # Smart log management
│   ├── nas_health.log              # Detailed monitoring log
│   ├── nas_health_status.json      # AI-ready health data
│   ├── ai_report_*.txt             # Generated AI reports
│   ├── performance_*.txt           # Speed test results
│   └── file_tree_*.txt             # Directory structure
└── ⚙️ config/
    └── nas_config.conf             # Your system configuration
```

## 🔧 Enhanced Usage Guide

### Basic Commands
```bash
# Run manual health check (now with performance testing)
sudo /opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh

# Use enhanced diagnostic tool
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh

# Check automated monitoring status
sudo systemctl status nas-masterx-monitor.timer
```

### 🆕 Enhanced Diagnostic Tool Menu
Run the diagnostic tool for the improved user interface:
```bash
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
```

**New Menu Options:**
1. **Quick Health Status** - Instant system overview
2. **Generate AI Analysis Report** - Create AI-ready report
3. **View Log Files (Enhanced)** - Smart log viewer with auto-preview
4. **Check Hardware Details** - Storage device information
5. **Filesystem Information** - Mount and usage details
6. **Run Full Health Check** - Comprehensive system check
7. **🆕 Performance Test Only** - Run speed benchmarks
8. **🆕 Generate File Tree Only** - Create directory structure report

## 🤖 AI Integration Guide

### Getting AI Assistance
When you encounter issues, NAS MasterX v1.1 makes AI assistance even simpler:

**Generate Enhanced AI Report:**
```bash
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
# Choose option 2: "Generate AI Analysis Report"
```

**Share with AI:**
1. Copy the generated report content
2. Paste into your AI assistant (DeepSeek, ChatGPT, etc.)
3. Use this enhanced prompt:

```text
Here's my NAS health report from NAS MasterX v1.1. Please analyze and provide specific recovery steps:

[PASTE REPORT CONTENT]

My main symptoms: [describe what you're experiencing]
Consider the performance metrics and file structure in your analysis.
```

### 🆕 Enhanced AI Report Includes:
- Performance test results with speed analysis
- File structure summary for recovery planning
- Smart threshold-based recommendations
- Hardware health status with SMART data
- Historical trend analysis

## 📊 Understanding Outputs

### 🆕 Enhanced Log Files & Their Purpose
| Log File | Purpose | AI Ready | Retention | New in v1.1 |
|----------|---------|----------|-----------|-------------|
| nas_health_status.json | Structured health data | ✅ Yes | 7 days | Enhanced |
| ai_report_*.txt | Pre-formatted AI reports | ✅ Yes | 7 days | Performance data |
| performance_*.txt | Speed test results | ✅ Yes | 7 days | ✅ New |
| file_tree_*.txt | Directory structure | ⚠️ No | 7 days | ✅ New |
| nas_health.log | Detailed monitoring activity | ⚠️ No | 7 days | Enhanced |

### 🆕 Health Status Levels
| Status | Description | Action Required |
|--------|-------------|-----------------|
| ✅ HEALTHY | All systems normal | No action needed |
| ⚠️ WARNING | Minor issues detected | Monitor closely |
| 🚨 CRITICAL | Performance degradation | Immediate attention |
| 💀 FAILED | Hardware failure detected | Replace hardware |

### 🆕 What Gets Monitored in v1.1
**Enhanced Filesystem Health:**
- Mount status verification
- Disk usage with warning thresholds (80% warning, 90% critical)
- Inode usage tracking
- Filesystem-specific checks (XFS, EXT4, BTRFS, ZFS)

**New Performance Monitoring:**
- Read/write speed benchmarking
- Automatic performance threshold detection
- Disk health recommendations
- Speed degradation tracking

**🆕 File Structure Preservation:**
- Directory tree generation
- File count and structure documentation
- Recovery-ready structure reports

**Hardware Monitoring:**
- Block device detection
- SMART health status (if smartmontools installed)
- Storage device information
- Performance-based health assessment

**System Integration:**
- Automated hourly checks via systemd
- Journal logging for debugging
- Structured JSON outputs for AI analysis
- Automatic log cleanup

## 🗺️ Where to Find Everything

### Log Locations
```bash
# All logs directory
cd /opt/media_stack/NAS_MasterX/logs/

# Latest AI report (most recent)
ls -lt /opt/media_stack/NAS_MasterX/logs/ai_report_*.txt | head -1

# 🆕 Latest performance report
ls -lt /opt/media_stack/NAS_MasterX/logs/performance_*.txt | head -1

# 🆕 Latest file tree report
ls -lt /opt/media_stack/NAS_MasterX/logs/file_tree_*.txt | head -1

# Health status data
cat /opt/media_stack/NAS_MasterX/logs/nas_health_status.json | jq .

# Service logs
sudo journalctl -u nas-masterx-monitor.service
```

### Configuration Files
```bash
# Your system configuration
cat /opt/media_stack/NAS_MasterX/config/nas_config.conf

# Service configuration
sudo systemctl cat nas-masterx-monitor.service
```

### Script Locations
```bash
# Main monitoring script (enhanced)
/opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh

# Diagnostic tool (enhanced)
/opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
```

## 🆕 Enhanced Troubleshooting Guide

### Common Issues & Solutions
**❌ "Permission Denied" during installation**
```bash
# Ensure you're not running as root user
whoami
# Should NOT be 'root'
exit  # if you're root, exit to regular user
./nas_masterx_installer.sh
```

**❌ "NAS not detected"**
```bash
# Check if your storage is properly mounted
df -h
mount | grep nas

# Ensure the mount point exists and is mounted
sudo mount /dev/your-nas-device /mnt/nas
```

**❌ "Service not running"**
```bash
# Check service status
sudo systemctl status nas-masterx-monitor.timer

# Restart the service
sudo systemctl restart nas-masterx-monitor.timer
sudo systemctl daemon-reload
```

**❌ "Performance test failing"**
```bash
# Check available space
df -h /opt/media_stack/NAS_MasterX/

# Ensure NAS has enough space (200MB+ recommended)
df -h $NAS_MOUNT
```

### 🆕 Installation Failure Recovery
If installation fails during stress testing:

1. **Check the specific failed test**
2. **Review installation logs**
3. **Manual cleanup if needed:**
```bash
sudo systemctl stop nas-masterx-monitor.timer
sudo systemctl disable nas-masterx-monitor.timer
sudo rm -f /etc/systemd/system/nas-masterx-monitor.*
sudo systemctl daemon-reload
sudo rm -rf /opt/media_stack/NAS_MasterX/scripts/
```

4. **Re-run installer after cleanup**

### 🆕 Emergency Recovery Steps
1. **Don't panic** - Your data is likely safe
2. **Generate enhanced AI report** using diagnostic tool
3. **Check file tree structure** for recovery planning
4. **Review performance metrics** for hardware issues
5. **Share with AI** for guided recovery
6. **Follow instructions carefully**
7. **Backup data** before major changes

## 🔄 Maintenance & Updates

### Checking System Status
```bash
# Quick status check
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
# Choose option 1

# Service status
sudo systemctl status nas-masterx-monitor.timer

# Next scheduled run
sudo systemctl list-timers nas-masterx-monitor.timer
```

### 🆕 Enhanced Log Management
- Logs auto-rotate with 7-day retention
- Automatic cleanup of old performance and tree reports
- No manual cleanup needed
- JSON format maintained for AI compatibility

### 🆕 Updating the System
```bash
cd /opt/media_stack/NAS_MasterX
sudo ./nas_masterx_installer.sh
# The installer will auto-detect and upgrade existing installation
```

## 🎯 What to Expect

### After Successful Installation v1.1
**Immediate Results:**
- ✅ Custom monitoring scripts generated for your system
- ✅ Automated hourly health checks enabled
- ✅ Initial health report created
- ✅ Performance baseline established
- ✅ File tree structure documented
- ✅ Enhanced diagnostic tool available

**Ongoing Monitoring:**
- 📊 Hourly system health checks
- ⚡ Performance trend monitoring
- 🌲 Regular file structure updates
- 🤖 AI-ready reports generated on demand
- 📈 Historical health data maintained
- 🔔 Automatic issue detection

### 🆕 Normal Operation Signs
**Healthy System Indicators:**
- Service status: active (waiting)
- Timer: enabled
- Logs: New files generated hourly
- Performance: Speed within thresholds
- Reports: Clean bill of health in AI reports

**🆕 Warning Signs:**
- Service status: inactive or failed
- No new log files
- Performance degradation alerts
- High disk usage warnings
- Slow read/write speeds

## 🆕 Advanced Features

### Custom Configuration
Edit `/opt/media_stack/NAS_MasterX/config/nas_config.conf` for:
- Custom monitoring intervals
- Additional mount points
- Performance threshold adjustments
- Specific health check parameters
- Log retention periods

### Manual Health Checks
```bash
# Run comprehensive check (now with performance testing)
sudo /opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh

# Check specific components
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh

# 🆕 Run performance test only
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
# Choose option 7
```

### Integration with Other Tools
```bash
# Use with monitoring systems
cat /opt/media_stack/NAS_MasterX/logs/nas_health_status.json | jq '.health_status'

# 🆕 Performance monitoring integration
cat /opt/media_stack/NAS_MasterX/logs/performance_*.txt | grep "Speed"

# Schedule custom checks
crontab -e
# Add: 0 */4 * * * /opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh
```

## 🤝 Support & Community

### Getting Help
1. **Check this manual first** - Most issues are covered here
2. **Use the enhanced diagnostic tool** - It provides specific error information
3. **Generate AI report** - Get AI-powered troubleshooting
4. **Check service logs** - Detailed technical information
5. **Review performance metrics** - Identify hardware issues

### System Information
- **Version**: 1.1
- **Compatibility**: Fedora Server, RHEL, CentOS, Rocky Linux
- **License**: MIT
- **Support**: GitHub Issues

### Community Resources
- GitHub Repository: [Your Repo Link]
- Issue Tracker: [GitHub Issues]
- Discussions: [GitHub Discussions]

## 🚨 Emergency Procedures

### Data Preservation First
- All operations are read-only when possible
- No automatic repairs without confirmation
- File tree structure preserved for recovery
- Full system snapshot recommended before risky operations

### 🆕 When Things Go Wrong
1. **Stop automated monitoring:**
```bash
sudo systemctl stop nas-masterx-monitor.timer
```

2. **Generate enhanced report:**
```bash
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
```

3. **Check file tree structure** for data recovery planning

4. **Review performance metrics** for hardware issues

5. **Seek AI assistance** with the generated report

6. **Follow AI guidance** step by step

7. **Resume monitoring** after resolution

## 🎉 Ready to Protect Your NAS?

**NAS MasterX v1.1** - Because your data deserves intelligent protection with performance monitoring 🛡️⚡

### Get started in 3 simple steps:
1. **Download** the enhanced installer
2. **Run** `./nas_masterx_installer.sh`
3. **Let AI and performance monitoring** handle the rest!

[⬇️ Download Now] • [📖 View Source] • [🐛 Report Issues]

---

**NAS MasterX v1.1**: Automated monitoring meets AI-powered troubleshooting and performance intelligence for worry-free NAS management.

### 🆕 Version 1.1 Highlights
- 🚀 **Auto-Upgrade** from previous versions
- ⚡ **Performance Intelligence** with smart thresholds
- 🌲 **Data Recovery Ready** file tree documentation
- 🧹 **Smart Log Management** with auto-cleanup
- 🔧 **Enhanced Diagnostics** with stress testing
- 🤖 **AI-Optimized** reporting with performance data

**Your NAS has never been smarter!** 🧠
