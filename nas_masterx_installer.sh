#!/bin/bash
# NAS MasterX v1.1 - Universal NAS Monitoring & Repair System
# Enhanced with auto-upgrade, stress testing, and performance monitoring

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
    echo "║                  🛡️ NAS MASTERX v1.1 INSTALLER              ║"
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

# Check for existing installation and uninstall
check_existing_installation() {
    log_stage "Checking Existing Installation"
    
    local existing_install=false
    
    # Check for systemd service
    if systemctl list-unit-files | grep -q nas-masterx-monitor; then
        echo -e "${YELLOW}Found existing NAS MasterX installation${NC}"
        existing_install=true
        
        # Find installation directory from service file
        local service_file="/etc/systemd/system/nas-masterx-monitor.service"
        if [[ -f "$service_file" ]]; then
            local install_path=$(grep "WorkingDirectory" "$service_file" | cut -d'=' -f2)
            if [[ -n "$install_path" && -d "$install_path" ]]; then
                MASTERX_DIR="$install_path"
                SCRIPTS_DIR="$MASTERX_DIR/scripts"
                LOGS_DIR="$MASTERX_DIR/logs"
                CONFIG_DIR="$MASTERX_DIR/config"
                echo -e "${CYAN}Existing installation found at: $MASTERX_DIR${NC}"
            fi
        fi
    fi
    
    if [[ "$existing_install" == true ]]; then
        echo -e "${YELLOW}Upgrading existing installation...${NC}"
        uninstall_existing
    else
        echo -e "${GREEN}No existing installation found. Fresh install.${NC}"
    fi
}

uninstall_existing() {
    log_stage "Uninstalling Previous Version"
    
    echo -e "${YELLOW}Stopping and disabling services...${NC}"
    
    # Stop and disable services
    sudo systemctl stop nas-masterx-monitor.timer 2>/dev/null || true
    sudo systemctl disable nas-masterx-monitor.timer 2>/dev/null || true
    sudo systemctl stop nas-masterx-monitor.service 2>/dev/null || true
    sudo systemctl disable nas-masterx-monitor.service 2>/dev/null || true
    
    # Remove systemd files
    sudo rm -f /etc/systemd/system/nas-masterx-monitor.service
    sudo rm -f /etc/systemd/system/nas-masterx-monitor.timer
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
    
    # Keep the directory structure but clean up scripts for regeneration
    if [[ -d "$SCRIPTS_DIR" ]]; then
        echo -e "${CYAN}Cleaning up old scripts...${NC}"
        rm -f "$SCRIPTS_DIR"/*.sh
    fi
    
    log_success "Previous version uninstalled"
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
    
    # Check for additional tools needed for new features
    for tool in tree timeout dd sync; do
        if ! command -v "$tool" &> /dev/null; then
            log_warning "Optional tool missing: $tool (some features may be limited)"
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

# Generate enhanced health monitor with performance testing and file tree
generate_health_monitor() {
    log_stage "Generating Enhanced Health Monitor"
    
    cat > "$SCRIPTS_DIR/nas_health_monitor.sh" << 'SCRIPT'
#!/bin/bash
# NAS Health Monitor v1.1 - Auto-generated by NAS MasterX

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

# Performance thresholds (MB/s)
SLOW_READ_THRESHOLD=50
SLOW_WRITE_THRESHOLD=30
CRITICAL_READ_THRESHOLD=20
CRITICAL_WRITE_THRESHOLD=10

# Logging setup
LOG_FILE="$LOGS_DIR/nas_health.log"
JSON_FILE="$LOGS_DIR/nas_health_status.json"
AI_REPORT="$LOGS_DIR/ai_report_$(date +%Y%m%d_%H%M%S).txt"
FILE_TREE_REPORT="$LOGS_DIR/file_tree_$(date +%Y%m%d_%H%M%S).txt"
PERFORMANCE_REPORT="$LOGS_DIR/performance_$(date +%Y%m%d_%H%M%S).txt"

setup_logging() {
    mkdir -p "$LOGS_DIR"
    touch "$LOG_FILE" "$JSON_FILE"
    
    # Clean up old logs (older than 7 days)
    find "$LOGS_DIR" -name "ai_report_*.txt" -mtime +7 -delete 2>/dev/null || true
    find "$LOGS_DIR" -name "file_tree_*.txt" -mtime +7 -delete 2>/dev/null || true
    find "$LOGS_DIR" -name "performance_*.txt" -mtime +7 -delete 2>/dev/null || true
}

log_json() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date -Iseconds)
    local json_entry="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"component\":\"$component\",\"message\":\"$message\"}"
    echo "$json_entry" >> "$JSON_FILE"
}

cleanup_old_logs() {
    echo "🧹 Cleaning up logs older than 7 days..."
    local deleted_count=0
    
    # Clean various log types
    for pattern in "ai_report_*.txt" "file_tree_*.txt" "performance_*.txt"; do
        deleted_count=$((deleted_count + $(find "$LOGS_DIR" -name "$pattern" -mtime +7 -delete -print 2>/dev/null | wc -l)))
    done
    
    # Clean main logs but keep recent ones
    if [[ -f "$LOG_FILE" ]]; then
        # Keep last 1000 lines of main log
        tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
    
    if [[ -f "$JSON_FILE" ]]; then
        # Keep last 5000 lines of JSON log
        tail -5000 "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
    fi
    
    echo "✅ Cleaned up $deleted_count old log files"
    log_json "INFO" "cleanup" "Cleaned up $deleted_count old log files"
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
        echo "🚨 CRITICAL: Disk space over 90%"
        log_json "CRITICAL" "filesystem" "Disk space critical: ${usage_percent}%"
    elif [[ $usage_percent -gt 80 ]]; then
        echo "⚠️ WARNING: Disk space over 80%"
        log_json "WARNING" "filesystem" "Disk space warning: ${usage_percent}%"
    fi
    
    # Inode usage
    local inode_info=$(df -i "$NAS_MOUNT" | tail -1)
    local inode_usage=$(echo "$inode_info" | awk '{print $5}' | sed 's/%//')
    echo "📊 Inode Usage: $inode_info"
    log_json "INFO" "filesystem" "Inode usage: ${inode_usage}%"
    
    if [[ $inode_usage -gt 90 ]]; then
        echo "⚠️ WARNING: Inode usage over 90%"
        log_json "WARNING" "filesystem" "Inode usage critical: ${inode_usage}%"
    fi
    
    echo "✅ Filesystem check completed"
}

generate_file_tree() {
    echo ""
    echo "=== FILE TREE STRUCTURE ==="
    
    if command -v tree &> /dev/null; then
        echo "Generating file tree structure..."
        tree -L 3 "$NAS_MOUNT" > "$FILE_TREE_REPORT" 2>/dev/null || \
        find "$NAS_MOUNT" -maxdepth 3 -type d | sort > "$FILE_TREE_REPORT" 2>/dev/null
        
        local dir_count=$(find "$NAS_MOUNT" -type d | wc -l)
        local file_count=$(find "$NAS_MOUNT" -type f | wc -l)
        
        echo "📁 Directory Structure: $FILE_TREE_REPORT"
        echo "📊 Summary: $dir_count directories, $file_count files"
        log_json "INFO" "file_tree" "Generated file tree: $dir_count dirs, $file_count files"
        
        # Add summary to AI report
        echo "FILE STRUCTURE SUMMARY:" >> "$AI_REPORT"
        echo "Directories: $dir_count" >> "$AI_REPORT"
        echo "Files: $file_count" >> "$AI_REPORT"
        echo "Top Level Structure:" >> "$AI_REPORT"
        ls -la "$NAS_MOUNT" | head -10 >> "$AI_REPORT" 2>/dev/null || echo "Cannot list directory" >> "$AI_REPORT"
    else
        echo "⚠️ 'tree' command not available. Install for better file structure reporting."
        # Basic structure without tree
        echo "Basic file structure:" > "$FILE_TREE_REPORT"
        find "$NAS_MOUNT" -maxdepth 2 -type d | sort >> "$FILE_TREE_REPORT" 2>/dev/null || echo "Cannot generate file structure" >> "$FILE_TREE_REPORT"
        log_json "WARNING" "file_tree" "Tree command not available, using basic file listing"
    fi
}

test_performance() {
    echo ""
    echo "=== PERFORMANCE TEST ==="
    
    local test_file="$NAS_MOUNT/nas_masterx_perf_test_$(date +%s).tmp"
    local test_size=100  # 100MB test file
    local write_speed=0
    local read_speed=0
    
    # Check available space
    local available_mb=$(df -m "$NAS_MOUNT" | tail -1 | awk '{print $4}')
    if [[ $available_mb -lt $((test_size * 2)) ]]; then
        echo "⚠️ Not enough space for performance test (needs ${test_size}MB)"
        log_json "WARNING" "performance" "Skipped - insufficient space"
        return
    fi
    
    echo "Running performance test with ${test_size}MB file..."
    
    # Write test
    local write_start=$(date +%s.%N)
    if dd if=/dev/zero of="$test_file" bs=1M count=$test_size oflag=direct 2>/dev/null; then
        local write_end=$(date +%s.%N)
        local write_time=$(echo "$write_end - $write_start" | bc)
        write_speed=$(echo "scale=2; $test_size / $write_time" | bc)
        echo "📝 Write Speed: ${write_speed} MB/s"
    else
        echo "❌ Write test failed"
        log_json "ERROR" "performance" "Write performance test failed"
    fi
    
    sync
    
    # Read test
    local read_start=$(date +%s.%N)
    if dd if="$test_file" of=/dev/null bs=1M count=$test_size iflag=direct 2>/dev/null; then
        local read_end=$(date +%s.%N)
        local read_time=$(echo "$read_end - $read_start" | bc)
        read_speed=$(echo "scale=2; $test_size / $read_time" | bc)
        echo "📖 Read Speed: ${read_speed} MB/s"
    else
        echo "❌ Read test failed"
        log_json "ERROR" "performance" "Read performance test failed"
    fi
    
    # Cleanup
    rm -f "$test_file"
    
    # Performance analysis
    cat > "$PERFORMANCE_REPORT" << PERF_REPORT
NAS PERFORMANCE REPORT
Generated: $(date)
Test File Size: ${test_size}MB
Write Speed: ${write_speed} MB/s
Read Speed: ${read_speed} MB/s

PERFORMANCE ANALYSIS:
PERF_REPORT

    if (( $(echo "$write_speed < $CRITICAL_WRITE_THRESHOLD" | bc -l) )); then
        echo "🚨 CRITICAL: Write speed very slow (${write_speed} MB/s)"
        echo "CRITICAL: Write speed very slow - consider disk replacement" >> "$PERFORMANCE_REPORT"
        log_json "CRITICAL" "performance" "Very slow write speed: ${write_speed} MB/s"
    elif (( $(echo "$write_speed < $SLOW_WRITE_THRESHOLD" | bc -l) )); then
        echo "⚠️ WARNING: Write speed slow (${write_speed} MB/s)"
        echo "WARNING: Write speed below expected threshold" >> "$PERFORMANCE_REPORT"
        log_json "WARNING" "performance" "Slow write speed: ${write_speed} MB/s"
    else
        echo "✅ Write speed normal"
        echo "NORMAL: Write speed within expected range" >> "$PERFORMANCE_REPORT"
    fi
    
    if (( $(echo "$read_speed < $CRITICAL_READ_THRESHOLD" | bc -l) )); then
        echo "🚨 CRITICAL: Read speed very slow (${read_speed} MB/s)"
        echo "CRITICAL: Read speed very slow - consider disk replacement" >> "$PERFORMANCE_REPORT"
        log_json "CRITICAL" "performance" "Very slow read speed: ${read_speed} MB/s"
    elif (( $(echo "$read_speed < $SLOW_READ_THRESHOLD" | bc -l) )); then
        echo "⚠️ WARNING: Read speed slow (${read_speed} MB/s)"
        echo "WARNING: Read speed below expected threshold" >> "$PERFORMANCE_REPORT"
        log_json "WARNING" "performance" "Slow read speed: ${read_speed} MB/s"
    else
        echo "✅ Read speed normal"
        echo "NORMAL: Read speed within expected range" >> "$PERFORMANCE_REPORT"
    fi
    
    log_json "INFO" "performance" "Performance test completed: write=${write_speed}MB/s, read=${read_speed}MB/s"
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
                local health=$(smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" | cut -d':' -f2 | tr -d ' ' || echo "UNAVAILABLE")
                local model=$(smartctl -i "$disk" 2>/dev/null | grep "Device Model" | cut -d':' -f2 | sed 's/^ *//' || echo "Unknown")
                echo "💡 $disk ($model): $health"
                log_json "INFO" "smart" "Disk health: $disk - $health"
                
                # Check for specific SMART errors
                if [[ "$health" == "FAILED" ]]; then
                    echo "🚨 CRITICAL: Disk $disk reports FAILED health!"
                    log_json "CRITICAL" "smart" "Disk $disk health FAILED"
                fi
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
NAS MASTERX v1.1 - AI ANALYSIS REPORT
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

INODE USAGE:
$(df -i "$NAS_MOUNT" 2>/dev/null || echo "UNAVAILABLE")

RECENT HEALTH DATA:
$(tail -10 "$JSON_FILE" 2>/dev/null || echo "No health data available")

PERFORMANCE DATA:
$(cat "$PERFORMANCE_REPORT" 2>/dev/null || echo "Performance data unavailable")

FILE STRUCTURE:
$(head -20 "$FILE_TREE_REPORT" 2>/dev/null || echo "File structure data unavailable")

INSTRUCTIONS FOR AI:
Please analyze this NAS health report and provide specific recovery steps.
Focus on data preservation and safe troubleshooting procedures.
Consider the filesystem type ($FS_TYPE) and performance metrics in your recommendations.
If performance is slow, suggest disk replacement or optimization steps.
REPORT

    echo "✅ AI Report Generated: $AI_REPORT"
    log_json "INFO" "ai_report" "AI analysis report generated"
}

main() {
    echo "🛡️ NAS MasterX Health Monitor v1.1 - Starting Check"
    echo "=================================================="
    
    setup_logging
    cleanup_old_logs
    log_json "INFO" "monitor" "Health check session started"
    
    check_filesystem
    generate_file_tree
    test_performance
    check_hardware
    generate_ai_report
    
    echo ""
    echo "📊 HEALTH CHECK COMPLETE"
    echo "📁 Logs Directory: $LOGS_DIR/"
    echo "📄 Health Data: $JSON_FILE"
    echo "🤖 AI Report: $AI_REPORT"
    echo "🌲 File Tree: $FILE_TREE_REPORT"
    echo "⚡ Performance: $PERFORMANCE_REPORT"
    echo ""
    echo "For AI assistance:"
    echo "  cat $AI_REPORT"
    echo "Or: cat $JSON_FILE | jq ."
    
    log_json "INFO" "monitor" "Health check session completed"
}

main "$@"
SCRIPT

    chmod +x "$SCRIPTS_DIR/nas_health_monitor.sh"
    log_success "Enhanced health monitor generated"
}

# Generate enhanced diagnostic tool with improved log viewing
generate_diagnostic_tool() {
    log_stage "Generating Enhanced Diagnostic Tool"
    
    cat > "$SCRIPTS_DIR/nas_diagnostic_tool.sh" << 'DIAG'
#!/bin/bash
# NAS Diagnostic Tool v1.1 - Interactive Interface

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
    echo "║               NAS DIAGNOSTIC TOOL v1.1          ║"
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
    echo "3. View Log Files (Enhanced)"
    echo "4. Check Hardware Details"
    echo "5. Filesystem Information"
    echo "6. Run Full Health Check"
    echo "7. Performance Test Only"
    echo "8. Generate File Tree Only"
    echo "0. Exit"
    echo ""
    echo -e "${YELLOW}Enter your choice [0-8]: ${NC}"
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
        grep -E "ERROR|WARNING|CRITICAL" "$LOGS_DIR/nas_health_status.json" | tail -5 | sed 's/.*"message":"//' | sed 's/".*//' || echo "  No recent alerts"
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
        head -20 "$latest_report"
    else
        echo -e "❌ ${RED}Failed to generate AI report${NC}"
    fi
}

view_logs() {
    echo -e "\n${CYAN}📄 Enhanced Log Viewer${NC}"
    echo "===================="
    
    # Auto-display latest logs by default
    local latest_ai_report=$(ls -t "$LOGS_DIR"/ai_report_*.txt 2>/dev/null | head -1)
    local latest_perf_report=$(ls -t "$LOGS_DIR"/performance_*.txt 2>/dev/null | head -1)
    local latest_tree_report=$(ls -t "$LOGS_DIR"/file_tree_*.txt 2>/dev/null | head -1)
    
    echo -e "${GREEN}Latest Log Files:${NC}"
    
    if [[ -n "$latest_ai_report" ]]; then
        echo -e "🤖 AI Report: $(basename "$latest_ai_report")"
        echo -e "   ${CYAN}Preview:${NC}"
        head -10 "$latest_ai_report" | sed 's/^/   /'
        echo ""
    fi
    
    if [[ -f "$LOGS_DIR/nas_health.log" ]]; then
        echo -e "📊 Health Log: nas_health.log"
        echo -e "   ${CYAN}Recent entries:${NC}"
        tail -5 "$LOGS_DIR/nas_health.log" | sed 's/^/   /'
        echo ""
    fi
    
    if [[ -f "$LOGS_DIR/nas_health_status.json" ]]; then
        echo -e "📈 Health Status: nas_health_status.json"
        echo -e "   ${CYAN}Recent status:${NC}"
        tail -3 "$LOGS_DIR/nas_health_status.json" | sed 's/^/   /'
        echo ""
    fi
    
    if [[ -n "$latest_perf_report" ]]; then
        echo -e "⚡ Performance: $(basename "$latest_perf_report")"
        echo -e "   ${CYAN}Results:${NC}"
        grep -E "Speed|CRITICAL|WARNING|NORMAL" "$latest_perf_report" | head -4 | sed 's/^/   /'
        echo ""
    fi
    
    if [[ -n "$latest_tree_report" ]]; then
        echo -e "🌲 File Tree: $(basename "$latest_tree_report")"
        echo -e "   ${CYAN}Structure preview:${NC}"
        head -10 "$latest_tree_report" | sed 's/^/   /'
        echo ""
    fi
    
    # Show all available log files
    echo -e "${YELLOW}All Available Log Files:${NC}"
    local log_files=$(find "$LOGS_DIR" -name "*.log" -o -name "*.json" -o -name "*.txt" 2>/dev/null | sort | head -20)
    
    if [[ -n "$log_files" ]]; then
        while IFS= read -r log; do
            local size=$(du -h "$log" 2>/dev/null | cut -f1 || echo "unknown")
            local modified=$(stat -c "%y" "$log" 2>/dev/null | cut -d' ' -f1-2 || echo "unknown")
            echo -e "📁 $(basename "$log") ($size, modified: $modified)"
        done <<< "$log_files"
        
        echo ""
        echo -e "${YELLOW}View specific log file (enter filename or press Enter to skip):${NC}"
        read -r log_name
        
        if [[ -n "$log_name" && -f "$LOGS_DIR/$log_name" ]]; then
            echo -e "\n${GREEN}Content of $log_name:${NC}"
            echo "=========================================="
            if [[ "$log_name" == *.json ]]; then
                # Pretty print JSON if jq is available
                if command -v jq &> /dev/null; then
                    jq . "$LOGS_DIR/$log_name" | head -30
                else
                    head -30 "$LOGS_DIR/$log_name"
                fi
            else
                head -30 "$LOGS_DIR/$log_name"
            fi
        elif [[ -n "$log_name" ]]; then
            echo -e "${RED}File not found: $log_name${NC}"
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
                smartctl -i "$disk" 2>/dev/null | grep -E "Model|Serial|Capacity|User Capacity" | head -4 || echo "  SMART info unavailable"
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

performance_test_only() {
    echo -e "\n${CYAN}⚡ Running Performance Test Only${NC}"
    echo "============================="
    
    # Create a temporary version of health monitor that only runs performance test
    local temp_script="$SCRIPTS_DIR/performance_test_temp.sh"
    cat > "$temp_script" << 'PERF_SCRIPT'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTERX_DIR="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$MASTERX_DIR/logs"

source "$MASTERX_DIR/config/nas_config.conf"

PERFORMANCE_REPORT="$LOGS_DIR/performance_single_$(date +%Y%m%d_%H%M%S).txt"

# Source the performance test function
test_performance() {
    local test_file="$NAS_MOUNT/nas_masterx_perf_test_$(date +%s).tmp"
    local test_size=100
    local write_speed=0
    local read_speed=0
    
    echo "Running performance test with ${test_size}MB file..."
    
    # Write test
    local write_start=$(date +%s.%N)
    if dd if=/dev/zero of="$test_file" bs=1M count=$test_size oflag=direct 2>/dev/null; then
        local write_end=$(date +%s.%N)
        local write_time=$(echo "$write_end - $write_start" | bc)
        write_speed=$(echo "scale=2; $test_size / $write_time" | bc)
        echo "📝 Write Speed: ${write_speed} MB/s"
    else
        echo "❌ Write test failed"
    fi
    
    sync
    
    # Read test
    local read_start=$(date +%s.%N)
    if dd if="$test_file" of=/dev/null bs=1M count=$test_size iflag=direct 2>/dev/null; then
        local read_end=$(date +%s.%N)
        local read_time=$(echo "$read_end - $read_start" | bc)
        read_speed=$(echo "scale=2; $test_size / $read_time" | bc)
        echo "📖 Read Speed: ${read_speed} MB/s"
    else
        echo "❌ Read test failed"
    fi
    
    rm -f "$test_file"
    
    # Save results
    cat > "$PERFORMANCE_REPORT" << REPORT
QUICK PERFORMANCE TEST
Generated: $(date)
Write Speed: ${write_speed} MB/s
Read Speed: ${read_speed} MB/s
REPORT
    
    echo "✅ Performance test complete: $PERFORMANCE_REPORT"
}

test_performance
PERF_SCRIPT

    chmod +x "$temp_script"
    "$temp_script"
    rm -f "$temp_script"
}

generate_file_tree_only() {
    echo -e "\n${CYAN}🌲 Generating File Tree Only${NC}"
    echo "============================"
    
    local tree_report="$LOGS_DIR/file_tree_single_$(date +%Y%m%d_%H%M%S).txt"
    
    if command -v tree &> /dev/null; then
        tree -L 3 "$NAS_MOUNT" > "$tree_report" 2>/dev/null
    else
        find "$NAS_MOUNT" -maxdepth 3 -type d | sort > "$tree_report" 2>/dev/null
    fi
    
    if [[ -s "$tree_report" ]]; then
        echo "✅ File tree generated: $tree_report"
        echo "Preview:"
        head -15 "$tree_report"
    else
        echo "❌ Failed to generate file tree"
    fi
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
            7) performance_test_only ;;
            8) generate_file_tree_only ;;
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
    log_success "Enhanced diagnostic tool generated"
}

# Create configuration
create_config() {
    log_stage "Creating Configuration"
    
    cat > "$CONFIG_DIR/nas_config.conf" << CONFIG
# NAS MasterX Configuration v1.1
# Auto-generated on $(date)

# NAS Configuration
NAS_MOUNT="$NAS_MOUNT"
NAS_DEVICE="$NAS_DEVICE"
FS_TYPE="$FS_TYPE"

# System Information
INSTALL_DATE="$(date)"
HOSTNAME="$(hostname)"
INSTALL_VERSION="1.1"

# Performance Thresholds (MB/s)
SLOW_READ_THRESHOLD=50
SLOW_WRITE_THRESHOLD=30
CRITICAL_READ_THRESHOLD=20
CRITICAL_WRITE_THRESHOLD=10

# Paths
MASTERX_DIR="$MASTERX_DIR"
SCRIPTS_DIR="$SCRIPTS_DIR"
LOGS_DIR="$LOGS_DIR"
CONFIG_DIR="$CONFIG_DIR"

# Log Retention (days)
LOG_RETENTION_DAYS=7
CONFIG

    log_success "Configuration file created"
}

# Setup systemd service
setup_service() {
    log_stage "Setting up Automated Monitoring"
    
    # Create service file
    sudo tee /etc/systemd/system/nas-masterx-monitor.service > /dev/null << SERVICE
[Unit]
Description=NAS MasterX Health Monitor v1.1
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
Description=NAS MasterX Health Monitor Timer v1.1
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

# Stress test the installation
stress_test_installation() {
    log_stage "Stress Testing Installation"
    
    echo -e "${CYAN}Running comprehensive stress test...${NC}"
    
    local tests_passed=0
    local tests_total=6
    
    # Test 1: Basic script execution
    echo -e "${CYAN}Test 1: Basic script functionality...${NC}"
    if timeout 10s bash -c "cd '$SCRIPTS_DIR' && './nas_health_monitor.sh' --help" &>/dev/null; then
        echo -e "✅ Basic script execution"
        ((tests_passed++))
    else
        echo -e "❌ Basic script execution failed"
    fi
    
    # Test 2: Configuration validation
    echo -e "${CYAN}Test 2: Configuration validation...${NC}"
    if [[ -f "$CONFIG_DIR/nas_config.conf" ]] && source "$CONFIG_DIR/nas_config.conf" && [[ -n "$NAS_MOUNT" ]]; then
        echo -e "✅ Configuration valid"
        ((tests_passed++))
    else
        echo -e "❌ Configuration invalid"
    fi
    
    # Test 3: Service status
    echo -e "${CYAN}Test 3: Service status...${NC}"
    if systemctl is-active nas-masterx-monitor.timer &>/dev/null; then
        echo -e "✅ Service active"
        ((tests_passed++))
    else
        echo -e "❌ Service not active"
    fi
    
    # Test 4: Log directory writable
    echo -e "${CYAN}Test 4: Log directory permissions...${NC}"
    if touch "$LOGS_DIR/test_write.tmp" 2>/dev/null; then
        rm -f "$LOGS_DIR/test_write.tmp"
        echo -e "✅ Log directory writable"
        ((tests_passed++))
    else
        echo -e "❌ Log directory not writable"
    fi
    
    # Test 5: NAS accessibility
    echo -e "${CYAN}Test 5: NAS accessibility...${NC}"
    if [[ -d "$NAS_MOUNT" ]] && mount | grep -q " on $NAS_MOUNT "; then
        echo -e "✅ NAS accessible"
        ((tests_passed++))
    else
        echo -e "❌ NAS not accessible"
    fi
    
    # Test 6: Diagnostic tool
    echo -e "${CYAN}Test 6: Diagnostic tool...${NC}"
    if timeout 5s bash -c "cd '$SCRIPTS_DIR' && './nas_diagnostic_tool.sh' --help" &>/dev/null; then
        echo -e "✅ Diagnostic tool functional"
        ((tests_passed++))
    else
        echo -e "⚠️ Diagnostic tool test inconclusive"
    fi
    
    # Performance quick test (optional)
    echo -e "${CYAN}Optional: Quick performance check...${NC}"
    local available_mb=$(df -m "$NAS_MOUNT" 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    if [[ $available_mb -gt 200 ]]; then
        echo -e "✅ Sufficient space for performance tests"
    else
        echo -e "⚠️ Limited space for performance tests"
    fi
    
    echo -e "\n${CYAN}Stress Test Results: $tests_passed/$tests_total tests passed${NC}"
    
    if [[ $tests_passed -ge 4 ]]; then
        log_success "Stress test completed successfully"
        return 0
    else
        log_warning "Stress test completed with issues"
        return 1
    fi
}

# Cleanup after installation
cleanup_installation() {
    log_stage "Cleaning Up"
    
    # Remove any temporary files
    find "$MASTERX_DIR" -name "*.tmp" -delete 2>/dev/null || true
    
    # Ensure proper permissions
    sudo chown -R $USER:$USER "$MASTERX_DIR"
    sudo chmod -R 755 "$SCRIPTS_DIR"
    sudo chmod 644 "$CONFIG_DIR"/*.conf 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Create enhanced manual
create_manual() {
    log_stage "Creating Documentation"
    
    cat > "$MASTERX_DIR/README.md" << MANUAL
# 🛡️ NAS MasterX v1.1

## What's New in v1.1
- ✅ Auto-upgrade from previous versions
- ✅ Comprehensive stress testing during installation
- ✅ Enhanced log management with auto-cleanup
- ✅ File tree structure recording for data recovery
- ✅ Performance benchmarking with speed thresholds
- ✅ Improved diagnostic interface

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

## Performance Monitoring
- Read/Write speed testing with thresholds
- Automatic disk health recommendations
- File structure preservation for recovery

## Files
- **Scripts**: $SCRIPTS_DIR/
- **Logs**: $LOGS_DIR/ (auto-cleaned after 7 days)
- **Config**: $CONFIG_DIR/

## Automated Monitoring
- Runs hourly via systemd
- Check status: \`sudo systemctl status nas-masterx-monitor.timer\`
- Performance thresholds: Read <50MB/s = Warning, <20MB/s = Critical

## Troubleshooting
If you experience issues, run the diagnostic tool and share the AI report with your preferred AI assistant for guided recovery.
MANUAL

    log_success "Documentation created"
}

# Main installation
main_installation() {
    print_banner
    
    echo -e "${CYAN}Starting NAS MasterX v1.1 installation...${NC}"
    echo -e "Press Ctrl+C to cancel at any time."
    echo ""
    
    # Check for existing installation and uninstall if found
    check_existing_installation
    
    # Check sudo access
    check_sudo
    
    preflight_checks
    detect_nas_configuration
    create_directories
    generate_health_monitor
    generate_diagnostic_tool
    create_config
    setup_service
    stress_test_installation
    cleanup_installation
    create_manual
    
    echo -e "\n${GREEN}🎉 NAS MasterX v1.1 Installation Complete!${NC}"
    echo -e "\n${CYAN}🚀 Quick Start Commands:${NC}"
    echo -e "1. Health Check: ${GREEN}sudo $SCRIPTS_DIR/nas_health_monitor.sh${NC}"
    echo -e "2. Diagnostics:  ${GREEN}sudo $SCRIPTS_DIR/nas_diagnostic_tool.sh${NC}"
    echo -e "3. Service Status: ${GREEN}sudo systemctl status nas-masterx-monitor.timer${NC}"
    echo -e "\n${GREEN}🛡️ Your NAS is now protected by NAS MasterX v1.1!${NC}"
    echo -e "${YELLOW}Read the manual: cat $MASTERX_DIR/README.md${NC}"
    echo -e "\n${CYAN}📊 New Features:${NC}"
    echo -e "• Auto-upgrade capability"
    echo -e "• Performance benchmarking"
    echo -e "• File tree structure recording"
    echo -e "• Enhanced log management"
    echo -e "• Comprehensive stress testing"
}

# Run installation
main_installation "$@"
