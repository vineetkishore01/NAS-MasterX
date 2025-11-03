# 🛡️ NAS MasterX - NAS Monitoring & Repair System for Fedora Server

![Fedora](https://img.shields.io/badge/Fedora-Compatible-blue)
![Bash](https://img.shields.io/badge/Bash-Script-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![AI-Ready](https://img.shields.io/badge/AI--Ready-Reports-orange)

## 📖 Overview

**NAS MasterX** is an intelligent, auto-detecting NAS monitoring system that provides enterprise-grade monitoring for home and small business users. It automatically detects your NAS configuration and creates custom monitoring scripts tailored to your specific setup.

### 🎯 What Problem Does This Solve?

If you've ever struggled with:
- NAS suddenly running out of space
- Mysterious performance issues
- Uncertainty about disk health
- Complex recovery procedures
- Lack of clear monitoring tools

**NAS MasterX solves these with AI-powered, automated monitoring!**

## 🚀 Quick Start

### Prerequisites
- Fedora Server, RHEL, CentOS, or compatible Linux distribution
- A mounted NAS/storage volume
- sudo privileges

### Installation (One Command)

```bash
# Download and run the installer
sudo mkdir -p /opt/media_stack/NAS_MasterX
cd /opt/media_stack/NAS_MasterX
sudo curl -O https://raw.githubusercontent.com/SkullEnemyX/NAS_MasterX/main/nas_masterx_installer.sh
sudo chmod +x nas_masterx_installer.sh
./nas_masterx_installer.sh
```

### What Happens During Installation?

The installer will:
1. **Auto-detect** your NAS configuration (LVM, XFS, EXT4, BTRFS, etc.)
2. **Generate custom scripts** specifically for your system
3. **Set up automated monitoring** that runs hourly
4. **Create AI-ready reporting system**
5. **Build interactive diagnostic tools**

## 🏗️ How It Works

### Architecture Overview

```
NAS MasterX System
├── 🔍 Auto-Detection Engine
│   ├── Scans for largest storage volume
│   ├── Checks common mount points
│   ├── Detects LVM configurations
│   └── Identifies filesystem types
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

### Auto-Detection Process

The system uses multiple detection methods:

1. **Largest Volume Detection** - Finds your biggest storage mount
2. **Common Mount Points** - Checks `/mnt/nas`, `/storage`, `/media/nas`, etc.
3. **LVM Detection** - Identifies Logical Volume Manager setups
4. **Manual Fallback** - Asks for input if auto-detection fails

## 📁 System Structure

After installation, your system will have:

```
/opt/media_stack/NAS_MasterX/
├── 📄 nas_masterx_installer.sh     # Main installer
├── 📖 README.md                    # This manual
├── 🛠️ scripts/                     # Generated monitoring scripts
│   ├── nas_health_monitor.sh       # Main health monitor
│   └── nas_diagnostic_tool.sh      # Interactive diagnostics
├── 📊 logs/                        # All logs and reports
│   ├── nas_health.log              # Detailed monitoring log
│   ├── nas_health_status.json      # AI-ready health data
│   └── ai_report_*.txt             # Generated AI reports
└── ⚙️ config/
    └── nas_config.conf             # Your system configuration
```

## 🔧 Usage Guide

### Basic Commands

```bash
# Run manual health check
sudo /opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh

# Use interactive diagnostic tool
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh

# Check automated monitoring status
sudo systemctl status nas-masterx-monitor.timer
```

### Interactive Diagnostic Tool

Run the diagnostic tool for a user-friendly interface:

```bash
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
```

You'll see a menu with options:
- **1. Quick Health Status** - Instant system overview
- **2. Generate AI Analysis Report** - Create AI-ready report
- **3. View Log Files** - Browse all generated logs
- **4. Check Hardware Details** - Storage device information
- **5. Filesystem Information** - Mount and usage details
- **6. Run Full Health Check** - Comprehensive system check

## 🤖 AI Integration Guide

### Getting AI Assistance

When you encounter issues, NAS MasterX makes AI assistance simple:

1. **Generate AI Report:**
   ```bash
   sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
   # Choose option 2: "Generate AI Analysis Report"
   ```

2. **Share with AI:**
   - Copy the generated report content
   - Paste into your AI assistant (DeepSeek, ChatGPT, etc.)
   - Use this prompt:
   ```
   Here's my NAS health report. Please analyze and provide specific recovery steps:
   
   [PASTE REPORT CONTENT]
   
   My main symptoms: [describe what you're experiencing]
   ```

3. **Direct JSON Analysis:**
   ```bash
   # For technical AI analysis
   cat /opt/media_stack/NAS_MasterX/logs/nas_health_status.json | jq .
   ```

### Example AI Prompt

> "Analyze this NAS health report. The system shows disk space at 85% usage and I'm experiencing slow file transfers. Provide step-by-step cleanup and optimization recommendations focusing on data preservation."

## 📊 Understanding Outputs

### Log Files & Their Purpose

| Log File | Purpose | AI Ready | Retention |
|----------|---------|----------|-----------|
| `nas_health_status.json` | Structured health data | ✅ Yes | 7 days |
| `ai_report_*.txt` | Pre-formatted AI reports | ✅ Yes | 7 days |
| `nas_health.log` | Detailed monitoring activity | ⚠️ No | 7 days |

### Health Status Levels

- ✅ **HEALTHY** - All systems normal, no action needed
- ⚠️ **WARNING** - Minor issues detected, monitor closely
- ❌ **CRITICAL** - Immediate attention required

### What Gets Monitored

**Filesystem Health:**
- Mount status verification
- Disk usage with warning thresholds (80% warning, 90% critical)
- Inode usage tracking
- Filesystem-specific checks (XFS, EXT4, BTRFS, ZFS)

**Hardware Monitoring:**
- Block device detection
- SMART health status (if smartmontools installed)
- Storage device information

**System Integration:**
- Automated hourly checks via systemd
- Journal logging for debugging
- Structured JSON outputs for AI analysis

## 🗺️ Where to Find Everything

### Log Locations
```bash
# All logs directory
cd /opt/media_stack/NAS_MasterX/logs/

# Latest AI report (most recent)
ls -lt /opt/media_stack/NAS_MasterX/logs/ai_report_*.txt | head -1

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
# Main monitoring script
/opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh

# Diagnostic tool
/opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
```

## 🆘 Troubleshooting Guide

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

**❌ "Scripts not executable"**
```bash
# Fix permissions
sudo chmod +x /opt/media_stack/NAS_MasterX/scripts/*.sh
```

### Installation Failure Recovery

If installation fails:

1. **Check the stage** where it failed
2. **Manual cleanup** if needed:
   ```bash
   sudo systemctl stop nas-masterx-monitor.timer
   sudo systemctl disable nas-masterx-monitor.timer
   sudo rm -f /etc/systemd/system/nas-masterx-monitor.*
   sudo systemctl daemon-reload
   sudo rm -rf /opt/media_stack/NAS_MasterX/scripts/
   ```

3. **Re-run installer** after cleanup

### Emergency Recovery Steps

1. **Don't panic** - Your data is likely safe
2. **Generate AI report** using diagnostic tool
3. **Share with AI** for guided recovery
4. **Follow instructions** carefully
5. **Backup data** before major changes

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

### Log Management
- Logs auto-rotate with 7-day retention
- No manual cleanup needed
- JSON format maintained for AI compatibility

### Updating the System
```bash
cd /opt/media_stack/NAS_MasterX
sudo ./nas_masterx_installer.sh
# The installer will update existing installation
```

## 🎯 What to Expect

### After Successful Installation

**Immediate Results:**
- ✅ Custom monitoring scripts generated for your system
- ✅ Automated hourly health checks enabled
- ✅ Initial health report created
- ✅ Interactive diagnostic tool available

**Ongoing Monitoring:**
- 📊 Hourly system health checks
- 🤖 AI-ready reports generated on demand
- 📈 Historical health data maintained
- 🔔 Automatic issue detection

### Normal Operation Signs

**Healthy System Indicators:**
- Service status: `active (waiting)`
- Timer: `enabled`
- Logs: New files generated hourly
- Reports: Clean bill of health in AI reports

**Warning Signs:**
- Service status: `inactive` or `failed`
- No new log files
- Error messages in diagnostic tool
- High disk usage warnings

## 🔍 Advanced Features

### Custom Configuration
Edit `/opt/media_stack/NAS_MasterX/config/nas_config.conf` for:
- Custom monitoring intervals
- Additional mount points
- Specific health check parameters

### Manual Health Checks
```bash
# Run comprehensive check
sudo /opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh

# Check specific components
sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
```

### Integration with Other Tools
```bash
# Use with monitoring systems
cat /opt/media_stack/NAS_MasterX/logs/nas_health_status.json | jq '.health_status'

# Schedule custom checks
crontab -e
# Add: 0 */4 * * * /opt/media_stack/NAS_MasterX/scripts/nas_health_monitor.sh
```

## 🤝 Support & Community

### Getting Help

1. **Check this manual first** - Most issues are covered here
2. **Use the diagnostic tool** - It provides specific error information
3. **Generate AI report** - Get AI-powered troubleshooting
4. **Check service logs** - Detailed technical information

### System Information
- **Version**: 1.0
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
- Full system snapshot recommended before risky operations

### When Things Go Wrong
1. **Stop automated monitoring:**
   ```bash
   sudo systemctl stop nas-masterx-monitor.timer
   ```

2. **Generate detailed report:**
   ```bash
   sudo /opt/media_stack/NAS_MasterX/scripts/nas_diagnostic_tool.sh
   ```

3. **Seek AI assistance** with the generated report
4. **Follow AI guidance** step by step
5. **Resume monitoring** after resolution

---

<div align="center">

## 🎉 Ready to Protect Your NAS?

**NAS MasterX** - *Because your data deserves the best protection* 🛡️

**Get started in 3 simple steps:**
1. Download the installer
2. Run `./nas_masterx_installer.sh` 
3. Let AI handle the rest!

[⬇️ Download Now] • [📖 View Source] • [🐛 Report Issues]

</div>

---

*NAS MasterX: Automated monitoring meets AI-powered troubleshooting for worry-free NAS management.*
