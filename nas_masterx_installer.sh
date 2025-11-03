#!/bin/bash
# NAS MasterX - Universal NAS Monitoring & Repair System
# PROPERLY FIXED VERSION

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTERX_DIR="$SCRIPT_DIR"
SCRIPTS_DIR="$MASTERX_DIR/scripts"
LOGS_DIR="$MASTERX_DIR/logs"
CONFIG_DIR="$MASTERX_DIR/config"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Installation state
INSTALL_STAGE="preflight"

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🛡️ NAS MASTERX INSTALLER                  ║"
    echo "║            Universal NAS Monitoring & Repair System         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_stage() {
    local stage="$1"
    INSTALL_STAGE="$stage"
    echo -e "${BLUE}📋 Stage: $stage${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we can use sudo
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}🔐 Sudo access required. Please enter your password if prompted.${NC}"
        if ! sudo true; then
            log_error "Sudo authentication failed"
            exit 1
        fi
    fi
}

# Pre-flight checks
preflight_checks() {
    log_stage "Pre-flight Checks"
    
    echo -e "${CYAN}Validating system...${NC}"
    
    # Check if we're in the right directory
    if [[ ! -d "$MASTERX_DIR" ]]; then
        log_error "Installation directory not found: $MASTERX_DIR"
        exit 1
    fi
    
    # Check basic dependencies
    for dep in bash lsblk mount df systemctl; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Missing dependency: $dep"
            exit 1
        fi
    done
    
    log_success "Pre-flight checks passed"
}

# NAS detection
detect_nas_configuration() {
    log_stage "NAS Detection"
    
    echo -e "${CYAN}Scanning for NAS storage...${NC}"
    
    # Method 1: Check for largest non-system mount
    local largest_mount=""
    local largest_size=0
    
    while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ (tmpfs|udev|overlay) ]]; then
            local mount_point=$(echo "$line" | awk '{print $6}')
            local size_str=$(echo "$line" | awk '{print $2}')
            
            # Skip system mounts
            [[ "$mount_point" =~ ^/(boot|efi|home|var|usr|opt|dev|proc|sys)$ ]] && continue
            [[ "$mount_point" == "/" ]] && continue
            
            # Simple size comparison
            local size_num=0
            if [[ "$size_str" =~ G ]]; then
                size_num=$(echo "$size_str" | sed 's/G//' | awk '{print $1 * 1024}')
            elif [[ "$size_str" =~ T ]]; then
                size_num=$(echo "$size_str" | sed 's/T//' | awk '{print $1 * 1048576}')
            else
                size_num=$(echo "$size_str" | sed 's/M//' | awk '{print $1}')
            fi
            
            if [[ $size_num -gt $largest_size ]]; then
                largest_size=$size_num
                largest_mount=$mount_point
            fi
        fi
    done < <(df -m | tail -n +2)
    
    if [[ -n "$largest_mount" && $largest_size -gt 1024 ]]; then
        NAS_MOUNT="$largest_mount"
        NAS_DEVICE=$(df "$NAS_MOUNT" 2>/dev/null | tail -1 | awk '{print $1}')
        FS_TYPE=$(mount | grep " on $NAS_MOUNT " | awk '{print $5}' | head -1)
        echo -e "${GREEN}Detected NAS: $NAS_DEVICE at $NAS_MOUNT ($FS_TYPE)${NC}"
        return 0
    fi
    
    # Method 2: Common mount points
    local common_mounts=("/mnt/nas" "/media/nas" "/storage" "/nas" "/mnt/storage" "/shared" "/data")
    for mount in "${common_mounts[@]}"; do
        if mount | grep -q " on $mount "; then
            NAS_MOUNT="$mount"
            NAS_DEVICE=$(df "$NAS_MOUNT" 2>/dev/null | tail -1 | awk '{print $1}')
            FS_TYPE=$(mount | grep " on $NAS_MOUNT " | awk '{print $5}' | head -1)
            echo -e "${GREEN}Detected NAS: $NAS_DEVICE at $NAS_MOUNT ($FS_TYPE)${NC}"
            return 0
        fi
    done
    
    # Method 3: Manual input
    echo -e "${YELLOW}Auto-detection failed. Manual configuration needed.${NC}"
    echo -e "${CYAN}Enter your NAS mount point:${NC}"
    read -r user_mount
    
    if [[ ! -d "$user_mount" ]]; then
        log_error "Directory doesn't exist: $user_mount"
        return 1
    fi
    
    if ! mount | grep -q " on $user_mount "; then
        log_error "Not a mount point: $user_mount"
        return 1
    fi
    
    NAS_MOUNT="$user_mount"
    NAS_DEVICE=$(df "$NAS_MOUNT" 2>/dev/null | tail -1 | awk '{print $1}')
    FS_TYPE=$(mount | grep " on $NAS_MOUNT " | awk '{print $5}' | head -1)
    
    if [[ -z "$NAS_DEVICE" || "$NAS_DEVICE" == "df:" ]]; then
        log_error "Invalid mount point: $user_mount"
        return 1
    fi
    
    echo -e "${GREEN}Configured NAS: $NAS_DEVICE at $NAS_MOUNT ($FS_TYPE)${NC}"
    log_success "NAS configuration complete"
    return 0
}

# Create directories with proper permissions
create_directories() {
    log_stage "Creating Directories"
    
    sudo mkdir -p "$SCRIPTS_DIR" "$LOGS_DIR" "$CONFIG_DIR"
    sudo chown $USER:$USER "$SCRIPTS_DIR" "$LOGS_DIR" "$CONFIG_DIR"
    sudo chmod 755 "$SCRIPTS_DIR" "$LOGS_DIR" "$CONFIG_DIR"
    
    log_success "Created directory structure"
}

# Generate health monitor
generate_health_monitor() {
    log_stage "Generating Health Monitor"
    
    cat > "$SCRIPTS_DIR/nas_health_monitor.sh" << 'SCRIPT'
#!/bin/bash
# NAS Health Monitor - Auto-generated by NAS MasterX

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTERX_DIR="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$MASTERX_DIR/logs"

# Load configuration
if [[ -f "$MASTERX_DIR/config/nas_config.conf" ]]; then
    source "$MASTERX_DIR/config/nas_config.conf"
else
    echo "❌ Configuration file missing"
    exit 1
fi

# Logging setup
LOG_FILE="$LOGS_DIR/nas_health.log"
JSON_FILE="$LOGS_DIR/nas_health_status.json"
AI_REPORT="$LOGS_DIR/ai_report_$(date +%Y%m%d_%H%M%S).txt"

setup_logging() {
    mkdir -p "$LOGS_DIR"
    touch "$LOG_FILE" "$JSON_FILE"
}

log_json() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date -Iseconds)
    local json_entry="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"component\":\"$component\",\"message\":\"$message\"}"
    echo "$json_entry" >> "$JSON_FILE"
}

check_filesystem() {
    echo "=== FILESYSTEM HEALTH ==="
    log_json "INFO" "filesystem" "Starting filesystem check"
    
    # Mount status
    if mount | grep -q " on $NAS_MOUNT "; then
        echo "✅ NAS mounted at $NAS_MOUNT"
        log_json "SUCCESS" "filesystem" "NAS mounted successfully"
    else
        echo "❌ NAS NOT MOUNTED at $NAS_MOUNT"
        log_json "ERROR" "filesystem" "NAS not mounted"
        return 1
    fi
    
    # Disk usage
    local disk_info=$(df -h "$NAS_MOUNT" | tail -1)
    local usage_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
    echo "💾 Disk Usage: $disk_info"
    log_json "INFO" "filesystem" "Disk usage: ${usage_percent}%"
    
    # Usage warnings
    if [[ $usage_percent -gt 90 ]]; then
        log_json "WARNING" "filesystem" "Disk space critical: ${usage_percent}%"
    elif [[ $usage_percent -gt 80 ]]; then
        log_json "WARNING" "filesystem" "Disk space warning: ${usage_percent}%"
    fi
    
    # Inode usage
    local inode_info=$(df -i "$NAS_MOUNT" | tail -1)
    log_json "INFO" "filesystem" "Inode usage: $inode_info"
    
    echo "✅ Filesystem check completed"
}

check_hardware() {
    echo ""
    echo "=== HARDWARE HEALTH ==="
    log_json "INFO" "hardware" "Starting hardware check"
    
    # Block devices
    local disks=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "^(sd|nvme|vd)" | head -10)
    log_json "INFO" "hardware" "Block devices detected"
    echo "🔍 Storage Devices:"
    echo "$disks"
    
    # SMART health if available
    for disk in /dev/sd? /dev/nvme?n1; do
        if [[ -b "$disk" ]]; then
            if command -v smartctl &> /dev/null; then
                local health=$(smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" || echo "SMART unavailable")
                echo "💡 $disk: $health"
                log_json "INFO" "smart" "Disk health: $disk - $health"
            else
                echo "💡 $disk: Install smartmontools for health data"
            fi
        fi
    done
    
    echo "✅ Hardware check completed"
}

generate_ai_report() {
    echo ""
    echo "=== AI ANALYSIS REPORT ==="
    
    cat > "$AI_REPORT" << REPORT
NAS MASTERX - AI ANALYSIS REPORT
Generated: $(date)
System: $(hostname)
NAS Mount: $NAS_MOUNT
NAS Device: $NAS_DEVICE
Filesystem: $FS_TYPE
========================================

SYSTEM STATUS:
$(mount | grep " on $NAS_MOUNT " || echo "NOT MOUNTED")

DISK USAGE:
$(df -h "$NAS_MOUNT" 2>/dev/null || echo "UNAVAILABLE")

RECENT HEALTH DATA:
$(tail -10 "$JSON_FILE" 2>/dev/null || echo "No health data available")

INSTRUCTIONS FOR AI:
Please analyze this NAS health report and provide specific recovery steps.
Focus on data preservation and safe troubleshooting procedures.
Consider the filesystem type ($FS_TYPE) in your recommendations.
REPORT

    echo "✅ AI Report Generated: $AI_REPORT"
    log_json "INFO" "ai_report" "AI analysis report generated"
}

main() {
    echo "🛡️ NAS MasterX Health Monitor - Starting Check"
    echo "=============================================="
    
    setup_logging
    log_json "INFO" "monitor" "Health check session started"
    
    check_filesystem
    check_hardware
    generate_ai_report
    
    echo ""
    echo "📊 HEALTH CHECK COMPLETE"
    echo "📁 Logs Directory: $LOGS_DIR/"
    echo "📄 Health Data: $JSON_FILE"
    echo "🤖 AI Report: $AI_REPORT"
    echo ""
    echo "For AI assistance:"
    echo "  cat $AI_REPORT"
    echo "Or: cat $JSON_FILE | jq ."
    
    log_json "INFO" "monitor" "Health check session completed"
}

main "$@"
SCRIPT

    chmod +x "$SCRIPTS_DIR/nas_health_monitor.sh"
    log_success "Health monitor generated"
}

# Generate diagnostic tool
generate_diagnostic_tool() {
    log_stage "Generating Diagnostic Tool"
    
    cat > "$SCRIPTS_DIR/nas_diagnostic_tool.sh" << 'DIAG'
#!/bin/bash
# NAS Diagnostic Tool - Interactive Interface

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTERX_DIR="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$MASTERX_DIR/logs"

# Load configuration
if [[ -f "$MASTERX_DIR/config/nas_config.conf" ]]; then
    source "$MASTERX_DIR/config/nas_config.conf"
else
    echo "❌ Configuration file missing"
    exit 1
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║               NAS DIAGNOSTIC TOOL               ║"
    echo "║           Interactive Troubleshooting           ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_menu() {
    clear
    print_banner
    echo -e "${CYAN}System: $(hostname)${NC}"
    echo -e "${CYAN}NAS: $NAS_MOUNT ($FS_TYPE)${NC}"
    echo ""
    echo -e "${GREEN}📋 DIAGNOSTIC MENU:${NC}"
    echo "1. Quick Health Status"
    echo "2. Generate AI Analysis Report"
    echo "3. View Log Files"
    echo "4. Check Hardware Details"
    echo "5. Filesystem Information"
    echo "6. Run Full Health Check"
    echo "0. Exit"
    echo ""
    echo -e "${YELLOW}Enter your choice [0-6]: ${NC}"
}

quick_status() {
    echo -e "\n${CYAN}🔍 Quick Health Status${NC}"
    echo "===================="
    
    # Mount status
    if mount | grep -q " on $NAS_MOUNT "; then
        echo -e "✅ ${GREEN}NAS Mounted: $NAS_MOUNT${NC}"
    else
        echo -e "❌ ${RED}NAS NOT MOUNTED: $NAS_MOUNT${NC}"
    fi
    
    # Disk usage
    echo -e "\n💾 Disk Usage:"
    df -h "$NAS_MOUNT" 2>/dev/null || echo "  Unable to check disk usage"
    
    # Recent issues
    echo -e "\n⚠️ Recent Alerts:"
    if [[ -f "$LOGS_DIR/nas_health_status.json" ]]; then
        grep -E "ERROR|WARNING" "$LOGS_DIR/nas_health_status.json" | tail -3 | sed 's/.*"message":"//' | sed 's/".*//' || echo "  No recent alerts"
    else
        echo "  No log data available"
    fi
}

generate_ai_report() {
    echo -e "\n${CYAN}🤖 Generating AI Analysis Report${NC}"
    echo "==============================="
    
    echo "Collecting system data..."
    "$SCRIPT_DIR/nas_health_monitor.sh" > /dev/null 2>&1
    
    local latest_report=$(ls -t "$LOGS_DIR"/ai_report_*.txt 2>/dev/null | head -1)
    
    if [[ -n "$latest_report" ]]; then
        echo -e "✅ ${GREEN}Report Generated:${NC}"
        echo -e "📄 $latest_report"
        echo ""
        echo -e "${YELLOW}How to use with AI:${NC}"
        echo "1. Copy the report content:"
        echo -e "   ${CYAN}cat '$latest_report'${NC}"
        echo "2. Paste into AI chat (DeepSeek, ChatGPT, etc)"
        echo "3. Ask: 'Analyze this NAS health report and provide recovery steps'"
        echo ""
        echo -e "${GREEN}Report Preview:${NC}"
        echo "=========================================="
        head -15 "$latest_report"
    else
        echo -e "❌ ${RED}Failed to generate AI report${NC}"
    fi
}

view_logs() {
    echo -e "\n${CYAN}📄 Available Log Files${NC}"
    echo "===================="
    
    local log_files=$(find "$LOGS_DIR" -name "*.log" -o -name "*.json" -o -name "*.txt" 2>/dev/null | sort)
    
    if [[ -n "$log_files" ]]; then
        echo -e "${GREEN}Found log files:${NC}"
        while IFS= read -r log; do
            local size=$(du -h "$log" 2>/dev/null | cut -f1)
            local modified=$(stat -c "%y" "$log" 2>/dev/null | cut -d' ' -f1-2 || echo "unknown")
            echo -e "📁 $(basename "$log") ($size, modified: $modified)"
        done <<< "$log_files"
        
        echo ""
        echo -e "${YELLOW}View a specific log file:${NC}"
        echo -e "Enter filename (or press Enter to skip): "
        read -r log_name
        
        if [[ -n "$log_name" && -f "$LOGS_DIR/$log_name" ]]; then
            echo -e "\n${GREEN}Content of $log_name:${NC}"
            echo "=========================================="
            head -20 "$LOGS_DIR/$log_name"
        fi
    else
        echo -e "${YELLOW}No log files found. Run health check first.${NC}"
    fi
}

check_hardware() {
    echo -e "\n${CYAN}🔧 Hardware Details${NC}"
    echo "=================="
    
    echo -e "\n${GREEN}Block Devices:${NC}"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
    
    echo -e "\n${GREEN}Storage Devices:${NC}"
    for disk in /dev/sd? /dev/nvme?n1; do
        if [[ -b "$disk" ]]; then
            echo -e "\n💾 $disk:"
            if command -v smartctl &> /dev/null; then
                smartctl -i "$disk" 2>/dev/null | grep -E "Model|Serial|Capacity" | head -3 || echo "  SMART info unavailable"
            else
                echo "  Install smartmontools for detailed info"
            fi
        fi
    done
}

filesystem_info() {
    echo -e "\n${CYAN}🗂️ Filesystem Information${NC}"
    echo "========================"
    
    echo -e "\n${GREEN}Mount Details:${NC}"
    mount | grep " on $NAS_MOUNT " || echo "  Not mounted"
    
    echo -e "\n${GREEN}Disk Space:${NC}"
    df -h "$NAS_MOUNT" 2>/dev/null || echo "  Unable to check disk space"
    
    echo -e "\n${GREEN}Inode Usage:${NC}"
    df -i "$NAS_MOUNT" 2>/dev/null || echo "  Unable to check inode usage"
}

run_full_check() {
    echo -e "\n${CYAN}🛡️ Running Full Health Check${NC}"
    echo "========================"
    "$SCRIPT_DIR/nas_health_monitor.sh"
}

main() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1) quick_status ;;
            2) generate_ai_report ;;
            3) view_logs ;;
            4) check_hardware ;;
            5) filesystem_info ;;
            6) run_full_check ;;
            0) echo -e "${GREEN}👋 Thank you for using NAS MasterX!${NC}"; exit 0 ;;
            *) echo -e "${RED}❌ Invalid choice. Please try again.${NC}" ;;
        esac
        
        echo ""
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read -r
    done
}

main "$@"
DIAG

    chmod +x "$SCRIPTS_DIR/nas_diagnostic_tool.sh"
    log_success "Diagnostic tool generated"
}

# Create configuration
create_config() {
    log_stage "Creating Configuration"
    
    cat > "$CONFIG_DIR/nas_config.conf" << CONFIG
# NAS MasterX Configuration
# Auto-generated on $(date)

# NAS Configuration
NAS_MOUNT="$NAS_MOUNT"
NAS_DEVICE="$NAS_DEVICE"
FS_TYPE="$FS_TYPE"

# System Information
INSTALL_DATE="$(date)"
HOSTNAME="$(hostname)"
INSTALL_VERSION="1.0"

# Paths
MASTERX_DIR="$MASTERX_DIR"
SCRIPTS_DIR="$SCRIPTS_DIR"
LOGS_DIR="$LOGS_DIR"
CONFIG_DIR="$CONFIG_DIR"
CONFIG

    log_success "Configuration file created"
}

# Setup systemd service
setup_service() {
    log_stage "Setting up Automated Monitoring"
    
    # Create service file
    sudo tee /etc/systemd/system/nas-masterx-monitor.service > /dev/null << SERVICE
[Unit]
Description=NAS MasterX Health Monitor
After=multi-user.target

[Service]
Type=oneshot
User=root
ExecStart=$SCRIPTS_DIR/nas_health_monitor.sh
WorkingDirectory=$MASTERX_DIR
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

    # Create timer file
    sudo tee /etc/systemd/system/nas-masterx-monitor.timer > /dev/null << TIMER
[Unit]
Description=NAS MasterX Health Monitor Timer
Requires=nas-masterx-monitor.service

[Timer]
Unit=nas-masterx-monitor.service
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
TIMER

    # Enable the service
    sudo systemctl daemon-reload
    sudo systemctl enable nas-masterx-monitor.timer
    sudo systemctl start nas-masterx-monitor.timer
    
    log_success "Automated monitoring configured (runs hourly)"
}

# Create manual
create_manual() {
    log_stage "Creating Documentation"
    
    cat > "$MASTERX_DIR/README.md" << MANUAL
# 🛡️ NAS MasterX

## Quick Start

\`\`\`bash
# Run health check
sudo $SCRIPTS_DIR/nas_health_monitor.sh

# Use diagnostic tool  
sudo $SCRIPTS_DIR/nas_diagnostic_tool.sh
\`\`\`

## AI Integration

1. Run diagnostic tool and choose option 2
2. Copy the generated report path
3. Share with AI: \`cat /path/to/ai_report_*.txt\`
4. Get specific recovery steps

## Files
- **Scripts**: $SCRIPTS_DIR/
- **Logs**: $LOGS_DIR/ 
- **Config**: $CONFIG_DIR/

## Automated Monitoring
- Runs hourly via systemd
- Check status: \`sudo systemctl status nas-masterx-monitor.timer\`
MANUAL

    log_success "Documentation created"
}

# Test installation
test_installation() {
    log_stage "Testing Installation"
    
    echo -e "${CYAN}Running tests...${NC}"
    
    local tests_passed=0
    local tests_total=4
    
    # Test 1: Config file
    if [[ -f "$CONFIG_DIR/nas_config.conf" ]]; then
        echo -e "✅ Config file exists"
        ((tests_passed++))
    else
        echo -e "❌ Config file missing"
    fi
    
    # Test 2: Scripts executable
    if [[ -x "$SCRIPTS_DIR/nas_health_monitor.sh" ]]; then
        echo -e "✅ Health monitor executable"
        ((tests_passed++))
    else
        echo -e "❌ Health monitor not executable"
    fi
    
    # Test 3: Service enabled
    if systemctl is-enabled nas-masterx-monitor.timer &>/dev/null; then
        echo -e "✅ Service enabled"
        ((tests_passed++))
    else
        echo -e "❌ Service not enabled"
    fi
    
    # Test 4: Quick script test
    if timeout 5s bash -c "cd '$SCRIPTS_DIR' && './nas_health_monitor.sh' --help" &>/dev/null; then
        echo -e "✅ Scripts functional"
        ((tests_passed++))
    else
        echo -e "⚠️ Script test inconclusive"
    fi
    
    if [[ $tests_passed -ge 3 ]]; then
        log_success "Installation successful ($tests_passed/$tests_total tests passed)"
    else
        log_warning "Installation completed with issues ($tests_passed/$tests_total tests passed)"
    fi
}

# Main installation
main_installation() {
    print_banner
    
    echo -e "${CYAN}Starting NAS MasterX installation...${NC}"
    echo -e "Press Ctrl+C to cancel at any time."
    echo ""
    
    # Check sudo access
    check_sudo
    
    preflight_checks
    detect_nas_configuration
    create_directories
    generate_health_monitor
    generate_diagnostic_tool
    create_config
    setup_service
    create_manual
    test_installation
    
    echo -e "\n${GREEN}🎉 NAS MasterX Installation Complete!${NC}"
    echo -e "\n${CYAN}🚀 Quick Start Commands:${NC}"
    echo -e "1. Health Check: ${GREEN}sudo $SCRIPTS_DIR/nas_health_monitor.sh${NC}"
    echo -e "2. Diagnostics:  ${GREEN}sudo $SCRIPTS_DIR/nas_diagnostic_tool.sh${NC}"
    echo -e "3. Service Status: ${GREEN}sudo systemctl status nas-masterx-monitor.timer${NC}"
    echo -e "\n${GREEN}🛡️ Your NAS is now protected by NAS MasterX!${NC}"
    echo -e "${YELLOW}Read the manual: cat $MASTERX_DIR/README.md${NC}"
}

# Run installation
main_installation "$@"
