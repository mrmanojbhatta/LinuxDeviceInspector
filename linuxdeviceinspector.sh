#!/usr/bin/env bash

# ============================================================================
# MANOJ BHATTA // LINUX DEVICE INSPECTOR
# ============================================================================
# READ-ONLY LINUX HARDWARE / DEVICE INSPECTION TOOL
#
# MENU
#   1. System Overview
#   2. Complete Device Information
#   3. Storage & Health
#   4. Battery & Power
#   5. Performance & Temperature
#   6. Network & Connectivity
#   7. Quick Check
#   8. Save Complete Report
#   9. Exit
#
# REPORT
#   ~/Downloads/Manoj_Device_Report_<HOST>_<TIMESTAMP>/
#       ├── Manoj_Device_Report.html
#       └── Manoj_Device_Report.pdf
#
# READ-ONLY:
#   This program only reads information exposed by Linux, firmware,
#   hardware interfaces and installed diagnostic utilities.
# ============================================================================

set -uo pipefail

# ============================================================================
# SUDO / NORMAL USER HANDLING
# ============================================================================

if [[ $EUID -ne 0 ]]; then

    export MANOJ_ORIGINAL_USER="${USER:-$(id -un)}"
    export MANOJ_ORIGINAL_HOME="${HOME:-}"

    exec sudo \
        --preserve-env=MANOJ_ORIGINAL_USER,MANOJ_ORIGINAL_HOME \
        "$0" "$@"
fi

ORIGINAL_USER="${SUDO_USER:-${MANOJ_ORIGINAL_USER:-root}}"

ORIGINAL_HOME="${MANOJ_ORIGINAL_HOME:-}"

if [[ -z "$ORIGINAL_HOME" || ! -d "$ORIGINAL_HOME" ]]; then
    ORIGINAL_HOME="$(
        getent passwd "$ORIGINAL_USER" 2>/dev/null |
        cut -d: -f6
    )"
fi

if [[ -z "$ORIGINAL_HOME" || ! -d "$ORIGINAL_HOME" ]]; then
    ORIGINAL_HOME="/home/$ORIGINAL_USER"
fi

ORIGINAL_GROUP="$(
    id -gn "$ORIGINAL_USER" 2>/dev/null ||
    echo "$ORIGINAL_USER"
)"

DOWNLOADS_DIR="$ORIGINAL_HOME/Downloads"

if [[ ! -d "$DOWNLOADS_DIR" ]]; then
    DOWNLOADS_DIR="$ORIGINAL_HOME"
fi

# ============================================================================
# BASIC INFORMATION
# ============================================================================

HOST="$(hostname 2>/dev/null || echo unknown)"
CHECKED_AT="$(date '+%Y-%m-%d %H:%M:%S')"

REPORT_DIR=""
HTML_REPORT=""
PDF_REPORT=""

# ============================================================================
# COLORS
# ============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    WHITE='\033[1;37m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    WHITE=''
    RESET=''
fi

# ============================================================================
# HELPERS
# ============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

pause_screen() {
    echo
    read -r -p "Press ENTER to continue..." _
}

screen_header() {

    clear

    echo
    echo -e "${CYAN}======================================================================${RESET}"
    echo -e "${WHITE}              MANOJ BHATTA // LINUX DEVICE INSPECTOR${RESET}"
    echo -e "${CYAN}======================================================================${RESET}"
    echo -e "${YELLOW} Host    : ${HOST}${RESET}"
    echo -e "${YELLOW} Checked : ${CHECKED_AT}${RESET}"
    echo -e "${CYAN}======================================================================${RESET}"
    echo
}

section() {

    echo
    echo -e "${CYAN}----------------------------------------------------------------------${RESET}"
    echo -e "${WHITE}$1${RESET}"
    echo -e "${CYAN}----------------------------------------------------------------------${RESET}"
}

print_value() {

    printf "%-28s : %s\n" "$1" "$2"
}

# ============================================================================
# 1. SYSTEM OVERVIEW
# ============================================================================

system_overview() {

    screen_header

    section "SYSTEM IDENTITY"

    print_value "Hostname" "$HOST"
    print_value "Date / Time" "$CHECKED_AT"
    print_value "Kernel" "$(uname -r 2>/dev/null || echo Unknown)"
    print_value "Architecture" "$(uname -m 2>/dev/null || echo Unknown)"

    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        print_value "Operating System" "${PRETTY_NAME:-Unknown}"
    fi

    if command_exists uptime; then
        print_value "Uptime" "$(uptime -p 2>/dev/null || echo Unknown)"
    fi

    section "CPU"

    if command_exists lscpu; then
        lscpu 2>/dev/null |
            grep -E \
            '^(Architecture|CPU\(s\)|Model name|Vendor ID|CPU family|Model|Thread|Core|Socket|CPU MHz|CPU max MHz|CPU min MHz)' \
            || true
    else
        print_value "Processor" "$(uname -p 2>/dev/null || echo Unknown)"
    fi

    section "MEMORY"

    if command_exists free; then
        free -h
    else
        echo "Memory information unavailable."
    fi

    section "ROOT FILESYSTEM"

    if command_exists df; then
        df -hT / 2>/dev/null || true
    fi

    pause_screen
}

# ============================================================================
# 2. COMPLETE DEVICE INFORMATION
# ============================================================================

complete_device_information() {

    screen_header

    section "SYSTEM"

    if command_exists hostnamectl; then
        hostnamectl 2>/dev/null || true
    fi

    section "DMI / SYSTEM HARDWARE"

    if command_exists dmidecode; then
        dmidecode -t system 2>/dev/null || true
    else
        echo "dmidecode is not installed."
    fi

    section "BIOS / UEFI"

    if command_exists dmidecode; then
        dmidecode -t bios 2>/dev/null || true
    else
        echo "dmidecode is not installed."
    fi

    section "MOTHERBOARD"

    if command_exists dmidecode; then
        dmidecode -t baseboard 2>/dev/null || true
    else
        echo "dmidecode is not installed."
    fi

    section "CPU"

    if command_exists lscpu; then
        lscpu 2>/dev/null || true
    fi

    section "MEMORY"

    if command_exists dmidecode; then
        dmidecode -t memory 2>/dev/null || true
    else
        free -h 2>/dev/null || true
    fi

    section "PCI DEVICES"

    if command_exists lspci; then
        lspci -nn 2>/dev/null || true
    else
        echo "lspci is not installed."
    fi

    section "USB DEVICES"

    if command_exists lsusb; then
        lsusb 2>/dev/null || true
    else
        echo "lsusb is not installed."
    fi

    section "BLOCK DEVICES"

    if command_exists lsblk; then
        lsblk -e 7 \
            -o NAME,TYPE,SIZE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL,TRAN \
            2>/dev/null || true
    fi

    pause_screen
}

# ============================================================================
# 3. STORAGE & HEALTH
# ============================================================================

storage_health() {

    screen_header

    section "BLOCK DEVICE SUMMARY"

    if command_exists lsblk; then
        lsblk -e 7 \
            -o NAME,TYPE,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL,SERIAL,TRAN \
            2>/dev/null || true
    fi

    section "FILESYSTEM USAGE"

    df -hT 2>/dev/null || true

    section "MOUNTED FILESYSTEMS"

    if command_exists findmnt; then
        findmnt -r 2>/dev/null || true
    fi

    section "DISK HEALTH"

    if command_exists smartctl; then

        mapfile -t DISKS < <(
            lsblk -dn -o NAME,TYPE 2>/dev/null |
            awk '$2=="disk"{print "/dev/"$1}'
        )

        if [[ ${#DISKS[@]} -eq 0 ]]; then
            echo "No physical disk detected."
        else

            for DISK in "${DISKS[@]}"; do

                echo
                echo "Device: $DISK"
                echo "----------------------------------------"

                smartctl -H "$DISK" 2>/dev/null |
                    grep -Ei \
                    'SMART overall-health|SMART Health Status|assessment|result' \
                    || echo "Health status not available."

                smartctl -A "$DISK" 2>/dev/null |
                    grep -Ei \
                    'Temperature|Percentage Used|Available Spare|Critical Warning|Power On Hours|Unsafe Shutdown|Media and Data Integrity|Error Information|Reallocated|Pending|Uncorrectable' \
                    || true

            done

        fi

    else

        echo "smartctl is not installed."
        echo "Install smartmontools for SMART information."

    fi

    section "NVMe HEALTH"

    if command_exists nvme; then

        mapfile -t NVME_DEVICES < <(
            lsblk -dn -o NAME,TYPE 2>/dev/null |
            awk '$1 ~ /^nvme[0-9]+n[0-9]+$/ && $2=="disk"{print "/dev/"$1}'
        )

        if [[ ${#NVME_DEVICES[@]} -eq 0 ]]; then

            echo "No NVMe device detected."

        else

            for NVME in "${NVME_DEVICES[@]}"; do

                echo
                echo "Device: $NVME"
                echo "----------------------------------------"

                nvme smart-log "$NVME" 2>/dev/null |
                    grep -E \
                    'critical_warning|temperature|available_spare|percentage_used|data_units_read|data_units_written|host_read_commands|host_write_commands|controller_busy_time|power_cycles|power_on_hours|unsafe_shutdowns|media_errors|num_err_log_entries|warning_temp_time|critical_comp_time' \
                    || echo "NVMe health information unavailable."

            done

        fi

    else

        echo "nvme-cli is not installed."

    fi

    pause_screen
}

# ============================================================================
# 4. BATTERY & POWER
# ============================================================================

battery_power() {

    screen_header

    section "BATTERY"

    BATTERIES=()

    if [[ -d /sys/class/power_supply ]]; then

        for BAT in /sys/class/power_supply/BAT*; do
            [[ -d "$BAT" ]] || continue
            BATTERIES+=("$BAT")
        done

    fi

    if [[ ${#BATTERIES[@]} -eq 0 ]]; then

        echo "No battery detected."

    else

        for BAT in "${BATTERIES[@]}"; do

            echo
            echo "Battery: $(basename "$BAT")"
            echo "----------------------------------------"

            print_value "Manufacturer" \
                "$(cat "$BAT/manufacturer" 2>/dev/null || echo Unknown)"

            print_value "Model" \
                "$(cat "$BAT/model_name" 2>/dev/null || echo Unknown)"

            print_value "Serial" \
                "$(cat "$BAT/serial_number" 2>/dev/null || echo Unknown)"

            print_value "Technology" \
                "$(cat "$BAT/technology" 2>/dev/null || echo Unknown)"

            print_value "Status" \
                "$(cat "$BAT/status" 2>/dev/null || echo Unknown)"

            print_value "Capacity" \
                "$(cat "$BAT/capacity" 2>/dev/null || echo Unknown)%"

            print_value "Cycle Count" \
                "$(cat "$BAT/cycle_count" 2>/dev/null || echo Unknown)"

            if [[ -r "$BAT/energy_full_design" &&
                  -r "$BAT/energy_full" ]]; then

                DESIGN="$(cat "$BAT/energy_full_design" 2>/dev/null || echo 0)"
                FULL="$(cat "$BAT/energy_full" 2>/dev/null || echo 0)"

                if [[ "$DESIGN" =~ ^[0-9]+$ &&
                      "$FULL" =~ ^[0-9]+$ &&
                      "$DESIGN" -gt 0 ]]; then

                    HEALTH=$((FULL * 100 / DESIGN))

                    print_value "Estimated Health" "${HEALTH}%"

                fi

            elif [[ -r "$BAT/charge_full_design" &&
                    -r "$BAT/charge_full" ]]; then

                DESIGN="$(cat "$BAT/charge_full_design" 2>/dev/null || echo 0)"
                FULL="$(cat "$BAT/charge_full" 2>/dev/null || echo 0)"

                if [[ "$DESIGN" =~ ^[0-9]+$ &&
                      "$FULL" =~ ^[0-9]+$ &&
                      "$DESIGN" -gt 0 ]]; then

                    HEALTH=$((FULL * 100 / DESIGN))

                    print_value "Estimated Health" "${HEALTH}%"

                fi

            fi

        done

    fi

    section "POWER SUPPLY"

    if [[ -d /sys/class/power_supply ]]; then

        for POWER in /sys/class/power_supply/*; do

            [[ -d "$POWER" ]] || continue

            TYPE="$(cat "$POWER/type" 2>/dev/null || true)"

            if [[ "$TYPE" == "Mains" ]]; then

                NAME="$(basename "$POWER")"

                echo
                echo "Power Adapter: $NAME"
                echo "----------------------------------------"

                print_value "Online" \
                    "$(cat "$POWER/online" 2>/dev/null || echo Unknown)"

            fi

        done

    fi

    section "THERMAL ZONES"

    if [[ -d /sys/class/thermal ]]; then

        FOUND=0

        for ZONE in /sys/class/thermal/thermal_zone*; do

            [[ -d "$ZONE" ]] || continue

            TYPE="$(cat "$ZONE/type" 2>/dev/null || echo Unknown)"
            TEMP="$(cat "$ZONE/temp" 2>/dev/null || echo Unknown)"

            if [[ "$TEMP" =~ ^[0-9]+$ ]]; then
                TEMP_C="$((TEMP / 1000))°C"
            else
                TEMP_C="$TEMP"
            fi

            print_value "$TYPE" "$TEMP_C"

            FOUND=1

        done

        [[ $FOUND -eq 1 ]] || echo "No thermal information available."

    else

        echo "Thermal information unavailable."

    fi

    pause_screen
}

# ============================================================================
# 5. PERFORMANCE & TEMPERATURE
# ============================================================================

performance_temperature() {

    screen_header

    section "SYSTEM LOAD"

    uptime 2>/dev/null || true

    if [[ -r /proc/loadavg ]]; then
        print_value "Load Average" "$(cat /proc/loadavg)"
    fi

    section "CPU"

    if command_exists lscpu; then

        lscpu 2>/dev/null |
            grep -E \
            '^(CPU\(s\)|On-line CPU|Model name|CPU MHz|CPU max MHz|CPU min MHz|Thread|Core|Socket)' \
            || true

    fi

    section "MEMORY"

    free -h 2>/dev/null || true

    section "SWAP"

    if command_exists swapon; then
        swapon --show 2>/dev/null || true
    fi

    section "CPU FREQUENCY"

    FOUND_FREQ=0

    for CPU in /sys/devices/system/cpu/cpu[0-9]*; do

        [[ -d "$CPU" ]] || continue

        FREQ_FILE="$CPU/cpufreq/scaling_cur_freq"

        if [[ -r "$FREQ_FILE" ]]; then

            FREQ="$(cat "$FREQ_FILE" 2>/dev/null || true)"

            if [[ "$FREQ" =~ ^[0-9]+$ ]]; then

                print_value \
                    "$(basename "$CPU") Frequency" \
                    "$((FREQ / 1000)) MHz"

                FOUND_FREQ=1

            fi

        fi

    done

    [[ $FOUND_FREQ -eq 1 ]] || echo "CPU frequency information unavailable."

    section "TEMPERATURE"

    if command_exists sensors; then
        sensors 2>/dev/null || true
    else
        echo "lm-sensors is not installed."
    fi

    section "TOP CPU PROCESSES"

    ps -eo pid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null |
        head -n 11

    section "TOP MEMORY PROCESSES"

    ps -eo pid,comm,%cpu,%mem --sort=-%mem 2>/dev/null |
        head -n 11

    pause_screen
}

# ============================================================================
# 6. NETWORK & CONNECTIVITY
# ============================================================================

network_connectivity() {

    screen_header

    section "NETWORK INTERFACES"

    if command_exists ip; then
        ip -br addr 2>/dev/null || true
    fi

    section "NETWORK LINKS"

    if command_exists ip; then
        ip -br link 2>/dev/null || true
    fi

    section "DEFAULT ROUTE"

    if command_exists ip; then

        ip route 2>/dev/null |
            grep '^default' ||
            echo "No default route detected."

    fi

    section "DNS"

    if command_exists resolvectl; then

        resolvectl status 2>/dev/null |
            grep -E \
            'Current DNS Server|DNS Servers|DNS Domain' ||
            true

    elif [[ -r /etc/resolv.conf ]]; then

        grep -E '^(nameserver|search)' \
            /etc/resolv.conf 2>/dev/null ||
            echo "DNS information unavailable."

    fi

    section "WIRELESS"

    if command_exists iw; then
        iw dev 2>/dev/null || true
    else
        echo "iw is not installed."
    fi

    section "NETWORK HARDWARE"

    if command_exists lspci; then

        lspci -nn 2>/dev/null |
            grep -Ei 'network|ethernet|wireless|wifi' ||
            echo "No PCI network information found."

    fi

    section "INTERNET CONNECTIVITY"

    if command_exists ping; then

        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
            echo -e "${GREEN}Internet connectivity: AVAILABLE${RESET}"
        else
            echo -e "${RED}Internet connectivity: NOT CONFIRMED${RESET}"
        fi

    else

        echo "ping is not available."

    fi

    section "DNS RESOLUTION"

    if command_exists getent; then

        if getent hosts example.com >/dev/null 2>&1; then
            echo -e "${GREEN}DNS resolution: AVAILABLE${RESET}"
        else
            echo -e "${RED}DNS resolution: NOT CONFIRMED${RESET}"
        fi

    fi

    pause_screen
}

# ============================================================================
# 7. QUICK CHECK
# ============================================================================

quick_check() {

    screen_header

    echo -e "${WHITE}QUICK DEVICE HEALTH CHECK${RESET}"
    echo

    section "OPERATING SYSTEM"

    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        print_value "OS" "${PRETTY_NAME:-Unknown}"
    fi

    print_value "Kernel" "$(uname -r 2>/dev/null || echo Unknown)"
    print_value "Architecture" "$(uname -m 2>/dev/null || echo Unknown)"

    section "CPU"

    CPU_MODEL="Unknown"

    if command_exists lscpu; then

        CPU_MODEL="$(
            lscpu 2>/dev/null |
            awk -F: '
            /^Model name/ {
                sub(/^[ \t]+/, "", $2)
                print $2
                exit
            }'
        )"

    fi

    print_value "CPU" "$CPU_MODEL"

    section "MEMORY"

    if command_exists free; then
        free -h
    fi

    section "STORAGE"

    if command_exists lsblk; then

        lsblk -dn -o NAME,SIZE,TYPE,MODEL,TRAN 2>/dev/null |
            awk '$3=="disk"'

    fi

    section "BATTERY"

    BATTERY_FOUND=0

    for BAT in /sys/class/power_supply/BAT*; do

        [[ -d "$BAT" ]] || continue

        BATTERY_FOUND=1

        print_value "Battery" "$(basename "$BAT")"
        print_value "Status" \
            "$(cat "$BAT/status" 2>/dev/null || echo Unknown)"
        print_value "Capacity" \
            "$(cat "$BAT/capacity" 2>/dev/null || echo Unknown)%"

    done

    [[ $BATTERY_FOUND -eq 1 ]] ||
        echo "No battery detected."

    section "TEMPERATURE"

    if command_exists sensors; then

        sensors 2>/dev/null |
            grep -Ei \
            'Package id|Core [0-9]+|Tctl|Tdie|temp[0-9]' ||
            echo "Temperature sensors did not return matching data."

    else

        echo "lm-sensors is not installed."

    fi

    section "NETWORK"

    if command_exists ip; then
        ip -br addr 2>/dev/null || true
    fi

    section "INTERNET"

    if command_exists ping; then

        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
            echo -e "${GREEN}PASS - Internet reachable${RESET}"
        else
            echo -e "${RED}CHECK - Internet not confirmed${RESET}"
        fi

    fi

    section "SMART"

    if command_exists smartctl; then
        echo -e "${GREEN}smartctl available${RESET}"
    else
        echo -e "${YELLOW}smartctl not installed${RESET}"
    fi

    section "NVMe TOOL"

    if command_exists nvme; then
        echo -e "${GREEN}nvme-cli available${RESET}"
    else
        echo -e "${YELLOW}nvme-cli not installed${RESET}"
    fi

    pause_screen
}

# ============================================================================
# HTML ESCAPING
# ============================================================================

html_escape() {

    sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g'
}

# ============================================================================
# HTML REPORT SECTION
# ============================================================================

report_section() {

    local TITLE="$1"

    cat >> "$HTML_REPORT" <<EOF
<section>
<h2>${TITLE}</h2>
<pre>
EOF
}

report_end_section() {

    cat >> "$HTML_REPORT" <<EOF
</pre>
</section>
EOF
}

# ============================================================================
# COLLECT COMMAND OUTPUT DIRECTLY INTO HTML
# ============================================================================

report_command() {

    "$@" 2>&1 |
        html_escape >> "$HTML_REPORT" || true
}

report_text() {

    printf '%s\n' "$1" |
        html_escape >> "$HTML_REPORT"
}

# ============================================================================
# CREATE HTML HEADER
# ============================================================================

create_html_header() {

    cat > "$HTML_REPORT" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>

<meta charset="UTF-8">

<meta name="viewport"
content="width=device-width, initial-scale=1.0">

<title>Manoj Bhatta - Linux Device Report</title>

<style>

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    padding: 0;
    background: #0b0f14;
    color: #d8dee9;
    font-family:
        Inter,
        "Segoe UI",
        Ubuntu,
        Arial,
        sans-serif;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 35px;
}

.header {
    background: linear-gradient(
        135deg,
        #111827,
        #0b0f14
    );

    border: 1px solid #273244;
    border-radius: 16px;

    padding: 30px;

    margin-bottom: 25px;
}

.brand {
    font-size: 30px;
    font-weight: 800;
    color: #ffffff;
}

.subtitle {
    margin-top: 8px;
    color: #8b98aa;
    font-size: 14px;
}

.meta {
    display: grid;
    grid-template-columns:
        repeat(auto-fit, minmax(220px, 1fr));

    gap: 12px;

    margin-top: 25px;
}

.meta-box {
    background: #111923;
    border: 1px solid #263244;
    border-radius: 10px;
    padding: 15px;
}

.meta-label {
    color: #718096;
    font-size: 12px;
    text-transform: uppercase;
    margin-bottom: 5px;
}

.meta-value {
    color: #ffffff;
    font-weight: 600;
    word-break: break-word;
}

section {
    background: #0f151d;
    border: 1px solid #222d3d;
    border-radius: 14px;

    margin-bottom: 20px;

    overflow: hidden;
}

h2 {
    margin: 0;

    padding: 17px 20px;

    background: #131c27;

    border-bottom: 1px solid #263244;

    color: #ffffff;

    font-size: 17px;
}

pre {
    margin: 0;

    padding: 20px;

    white-space: pre-wrap;
    word-break: break-word;

    font-family:
        "Ubuntu Mono",
        "DejaVu Sans Mono",
        monospace;

    font-size: 13px;

    line-height: 1.55;

    color: #cbd5e1;

    background: #0b1016;
}

.footer {
    text-align: center;

    margin-top: 30px;

    padding: 20px;

    color: #667085;

    font-size: 12px;
}

@media print {

    body {
        background: white;
        color: black;
    }

    .container {
        max-width: none;
        padding: 10px;
    }

    .header,
    section {
        break-inside: avoid;
    }

    section {
        border: 1px solid #cccccc;
    }

    h2 {
        color: black;
        background: #eeeeee;
    }

    pre {
        color: black;
        background: white;
        font-size: 9px;
    }

}

</style>

</head>

<body>

<div class="container">

<div class="header">

<div class="brand">
MANOJ BHATTA // LINUX DEVICE INSPECTOR
</div>

<div class="subtitle">
Read-only hardware, storage, battery, performance and network inspection
</div>

<div class="meta">

<div class="meta-box">
<div class="meta-label">Hostname</div>
<div class="meta-value">
$(printf '%s' "$HOST" | html_escape)
</div>
</div>

<div class="meta-box">
<div class="meta-label">Checked</div>
<div class="meta-value">
$(printf '%s' "$CHECKED_AT" | html_escape)
</div>
</div>

<div class="meta-box">
<div class="meta-label">User</div>
<div class="meta-value">
$(printf '%s' "$ORIGINAL_USER" | html_escape)
</div>
</div>

<div class="meta-box">
<div class="meta-label">Kernel</div>
<div class="meta-value">
$(uname -r 2>/dev/null | html_escape)
</div>
</div>

</div>

</div>
EOF
}

# ============================================================================
# REPORT: SYSTEM
# ============================================================================

report_system() {

    report_section "1. SYSTEM OVERVIEW"

    {
        echo "SYSTEM IDENTITY"
        echo "----------------"
        echo "Hostname     : $HOST"
        echo "Checked      : $CHECKED_AT"
        echo "Kernel       : $(uname -r 2>/dev/null || echo Unknown)"
        echo "Architecture : $(uname -m 2>/dev/null || echo Unknown)"

        if [[ -r /etc/os-release ]]; then
            . /etc/os-release
            echo "Operating OS : ${PRETTY_NAME:-Unknown}"
        fi

        if command_exists uptime; then
            echo "Uptime       : $(uptime -p 2>/dev/null || echo Unknown)"
        fi

        echo
        echo "CPU"
        echo "---"

        if command_exists lscpu; then
            lscpu 2>/dev/null |
                grep -E \
                '^(Architecture|CPU\(s\)|Model name|Vendor ID|CPU family|Model|Thread|Core|Socket|CPU MHz|CPU max MHz|CPU min MHz)' ||
                true
        fi

        echo
        echo "MEMORY"
        echo "------"

        free -h 2>/dev/null || true

        echo
        echo "ROOT FILESYSTEM"
        echo "---------------"

        df -hT / 2>/dev/null || true

    } | html_escape >> "$HTML_REPORT"

    report_end_section
}

# ============================================================================
# REPORT: DEVICE
# ============================================================================

report_device() {

    report_section "2. COMPLETE DEVICE INFORMATION"

    {
        echo "SYSTEM"
        echo "======"

        hostnamectl 2>/dev/null || true

        echo
        echo "DMI / SYSTEM HARDWARE"
        echo "====================="

        if command_exists dmidecode; then
            dmidecode -t system 2>/dev/null || true
        else
            echo "dmidecode is not installed."
        fi

        echo
        echo "BIOS / UEFI"
        echo "==========="

        if command_exists dmidecode; then
            dmidecode -t bios 2>/dev/null || true
        else
            echo "dmidecode is not installed."
        fi

        echo
        echo "MOTHERBOARD"
        echo "==========="

        if command_exists dmidecode; then
            dmidecode -t baseboard 2>/dev/null || true
        else
            echo "dmidecode is not installed."
        fi

        echo
        echo "CPU"
        echo "==="

        lscpu 2>/dev/null || true

        echo
        echo "MEMORY"
        echo "======"

        if command_exists dmidecode; then
            dmidecode -t memory 2>/dev/null || true
        fi

        echo
        echo "PCI DEVICES"
        echo "==========="

        lspci -nn 2>/dev/null || true

        echo
        echo "USB DEVICES"
        echo "==========="

        lsusb 2>/dev/null || true

        echo
        echo "BLOCK DEVICES"
        echo "============="

        lsblk -e 7 \
            -o NAME,TYPE,SIZE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL,TRAN \
            2>/dev/null || true

    } | html_escape >> "$HTML_REPORT"

    report_end_section
}

# ============================================================================
# REPORT: STORAGE
# ============================================================================

report_storage() {

    report_section "3. STORAGE & HEALTH"

    {
        echo "BLOCK DEVICES"
        echo "============="

        lsblk -e 7 \
            -o NAME,TYPE,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL,SERIAL,TRAN \
            2>/dev/null || true

        echo
        echo "FILESYSTEM USAGE"
        echo "================"

        df -hT 2>/dev/null || true

        echo
        echo "MOUNTED FILESYSTEMS"
        echo "==================="

        findmnt -r 2>/dev/null || true

        echo
        echo "SMART DISK HEALTH"
        echo "================="

        if command_exists smartctl; then

            mapfile -t DISKS < <(
                lsblk -dn -o NAME,TYPE 2>/dev/null |
                awk '$2=="disk"{print "/dev/"$1}'
            )

            for DISK in "${DISKS[@]}"; do

                echo
                echo "DEVICE: $DISK"
                echo "----------------------------------------"

                smartctl -H "$DISK" 2>/dev/null |
                    grep -Ei \
                    'SMART overall-health|SMART Health Status|assessment|result' ||
                    echo "Health status not available."

                smartctl -A "$DISK" 2>/dev/null |
                    grep -Ei \
                    'Temperature|Percentage Used|Available Spare|Critical Warning|Power On Hours|Unsafe Shutdown|Media and Data Integrity|Error Information|Reallocated|Pending|Uncorrectable' ||
                    true

            done

        else

            echo "smartctl is not installed."

        fi

        echo
        echo "NVMe HEALTH"
        echo "==========="

        if command_exists nvme; then

            mapfile -t NVME_DEVICES < <(
                lsblk -dn -o NAME,TYPE 2>/dev/null |
                awk '$1 ~ /^nvme[0-9]+n[0-9]+$/ && $2=="disk"{print "/dev/"$1}'
            )

            for NVME in "${NVME_DEVICES[@]}"; do

                echo
                echo "DEVICE: $NVME"
                echo "----------------------------------------"

                # Only SMART/health information.
                # Deliberately does NOT use:
                # nvme id-ctrl
                #
                # Therefore no:
                #   IDENTIFY CONTROLLER
                #   vid
                #   ssvid
                #   serial/controller dump

                nvme smart-log "$NVME" 2>/dev/null |
                    grep -E \
                    'critical_warning|temperature|available_spare|percentage_used|data_units_read|data_units_written|host_read_commands|host_write_commands|controller_busy_time|power_cycles|power_on_hours|unsafe_shutdowns|media_errors|num_err_log_entries|warning_temp_time|critical_comp_time' ||
                    echo "NVMe health information unavailable."

            done

        else

            echo "nvme-cli is not installed."

        fi

    } | html_escape >> "$HTML_REPORT"

    report_end_section
}

# ============================================================================
# REPORT: BATTERY
# ============================================================================

report_battery() {

    report_section "4. BATTERY & POWER"

    {
        echo "BATTERY"
        echo "======="

        BATTERY_FOUND=0

        for BAT in /sys/class/power_supply/BAT*; do

            [[ -d "$BAT" ]] || continue

            BATTERY_FOUND=1

            echo
            echo "Battery: $(basename "$BAT")"
            echo "----------------------------------------"

            echo "Manufacturer : $(cat "$BAT/manufacturer" 2>/dev/null || echo Unknown)"
            echo "Model        : $(cat "$BAT/model_name" 2>/dev/null || echo Unknown)"
            echo "Serial       : $(cat "$BAT/serial_number" 2>/dev/null || echo Unknown)"
            echo "Technology   : $(cat "$BAT/technology" 2>/dev/null || echo Unknown)"
            echo "Status       : $(cat "$BAT/status" 2>/dev/null || echo Unknown)"
            echo "Capacity     : $(cat "$BAT/capacity" 2>/dev/null || echo Unknown)%"
            echo "Cycle Count  : $(cat "$BAT/cycle_count" 2>/dev/null || echo Unknown)"

            if [[ -r "$BAT/energy_full_design" &&
                  -r "$BAT/energy_full" ]]; then

                DESIGN="$(cat "$BAT/energy_full_design" 2>/dev/null || echo 0)"
                FULL="$(cat "$BAT/energy_full" 2>/dev/null || echo 0)"

                if [[ "$DESIGN" =~ ^[0-9]+$ &&
                      "$FULL" =~ ^[0-9]+$ &&
                      "$DESIGN" -gt 0 ]]; then

                    echo "Estimated Health : $((FULL * 100 / DESIGN))%"

                fi

            elif [[ -r "$BAT/charge_full_design" &&
                    -r "$BAT/charge_full" ]]; then

                DESIGN="$(cat "$BAT/charge_full_design" 2>/dev/null || echo 0)"
                FULL="$(cat "$BAT/charge_full" 2>/dev/null || echo 0)"

                if [[ "$DESIGN" =~ ^[0-9]+$ &&
                      "$FULL" =~ ^[0-9]+$ &&
                      "$DESIGN" -gt 0 ]]; then

                    echo "Estimated Health : $((FULL * 100 / DESIGN))%"

                fi

            fi

        done

        if [[ $BATTERY_FOUND -eq 0 ]]; then
            echo "No battery detected."
        fi

        echo
        echo "POWER SUPPLY"
        echo "============"

        for POWER in /sys/class/power_supply/*; do

            [[ -d "$POWER" ]] || continue

            TYPE="$(cat "$POWER/type" 2>/dev/null || true)"

            if [[ "$TYPE" == "Mains" ]]; then

                echo
                echo "Power Adapter: $(basename "$POWER")"
                echo "Online: $(cat "$POWER/online" 2>/dev/null || echo Unknown)"

            fi

        done

        echo
        echo "THERMAL ZONES"
        echo "============="

        for ZONE in /sys/class/thermal/thermal_zone*; do

            [[ -d "$ZONE" ]] || continue

            TYPE="$(cat "$ZONE/type" 2>/dev/null || echo Unknown)"
            TEMP="$(cat "$ZONE/temp" 2>/dev/null || echo Unknown)"

            if [[ "$TEMP" =~ ^[0-9]+$ ]]; then
                TEMP="$((TEMP / 1000))°C"
            fi

            printf "%-25s : %s\n" "$TYPE" "$TEMP"

        done

    } | html_escape >> "$HTML_REPORT"

    report_end_section
}

# ============================================================================
# REPORT: PERFORMANCE
# ============================================================================

report_performance() {

    report_section "5. PERFORMANCE & TEMPERATURE"

    {
        echo "SYSTEM LOAD"
        echo "==========="

        uptime 2>/dev/null || true

        echo
        echo "LOAD AVERAGE"
        echo "============"

        cat /proc/loadavg 2>/dev/null || true

        echo
        echo "CPU"
        echo "==="

        lscpu 2>/dev/null |
            grep -E \
            '^(CPU\(s\)|On-line CPU|Model name|CPU MHz|CPU max MHz|CPU min MHz|Thread|Core|Socket)' ||
            true

        echo
        echo "MEMORY"
        echo "======"

        free -h 2>/dev/null || true

        echo
        echo "SWAP"
        echo "===="

        swapon --show 2>/dev/null || true

        echo
        echo "CPU FREQUENCY"
        echo "============="

        for CPU in /sys/devices/system/cpu/cpu[0-9]*; do

            [[ -d "$CPU" ]] || continue

            FREQ_FILE="$CPU/cpufreq/scaling_cur_freq"

            if [[ -r "$FREQ_FILE" ]]; then

                FREQ="$(cat "$FREQ_FILE" 2>/dev/null || true)"

                if [[ "$FREQ" =~ ^[0-9]+$ ]]; then

                    echo "$(basename "$CPU"): $((FREQ / 1000)) MHz"

                fi

            fi

        done

        echo
        echo "TEMPERATURE SENSORS"
        echo "==================="

        if command_exists sensors; then
            sensors 2>/dev/null || true
        else
            echo "lm-sensors is not installed."
        fi

        echo
        echo "TOP CPU PROCESSES"
        echo "================="

        ps -eo pid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null |
            head -n 11

        echo
        echo "TOP MEMORY PROCESSES"
        echo "===================="

        ps -eo pid,comm,%cpu,%mem --sort=-%mem 2>/dev/null |
            head -n 11

    } | html_escape >> "$HTML_REPORT"

    report_end_section
}

# ============================================================================
# REPORT: NETWORK
# ============================================================================

report_network() {

    report_section "6. NETWORK & CONNECTIVITY"

    {
        echo "NETWORK INTERFACES"
        echo "=================="

        ip -br addr 2>/dev/null || true

        echo
        echo "NETWORK LINKS"
        echo "============="

        ip -br link 2>/dev/null || true

        echo
        echo "DEFAULT ROUTE"
        echo "============="

        ip route 2>/dev/null |
            grep '^default' ||
            echo "No default route detected."

        echo
        echo "DNS"
        echo "==="

        if command_exists resolvectl; then

            resolvectl status 2>/dev/null |
                grep -E \
                'Current DNS Server|DNS Servers|DNS Domain' ||
                true

        elif [[ -r /etc/resolv.conf ]]; then

            grep -E '^(nameserver|search)' \
                /etc/resolv.conf 2>/dev/null ||
                true

        fi

        echo
        echo "WIRELESS"
        echo "========"

        if command_exists iw; then
            iw dev 2>/dev/null || true
        else
            echo "iw is not installed."
        fi

        echo
        echo "NETWORK HARDWARE"
        echo "================"

        lspci -nn 2>/dev/null |
            grep -Ei 'network|ethernet|wireless|wifi' ||
            true

        echo
        echo "INTERNET CONNECTIVITY"
        echo "====================="

        if command_exists ping; then

            if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
                echo "Internet connectivity: AVAILABLE"
            else
                echo "Internet connectivity: NOT CONFIRMED"
            fi

        fi

        echo
        echo "DNS RESOLUTION"
        echo "=============="

        if command_exists getent; then

            if getent hosts example.com >/dev/null 2>&1; then
                echo "DNS resolution: AVAILABLE"
            else
                echo "DNS resolution: NOT CONFIRMED"
            fi

        fi

    } | html_escape >> "$HTML_REPORT"

    report_end_section
}

# ============================================================================
# REPORT: QUICK CHECK
# ============================================================================

report_quick_check() {

    report_section "7. QUICK DEVICE CHECK"

    {
        echo "OPERATING SYSTEM"
        echo "================"

        if [[ -r /etc/os-release ]]; then
            . /etc/os-release
            echo "OS           : ${PRETTY_NAME:-Unknown}"
        fi

        echo "Kernel       : $(uname -r 2>/dev/null || echo Unknown)"
        echo "Architecture : $(uname -m 2>/dev/null || echo Unknown)"

        echo
        echo "CPU"
        echo "==="

        lscpu 2>/dev/null |
            grep -E '^Model name' ||
            true

        echo
        echo "MEMORY"
        echo "======"

        free -h 2>/dev/null || true

        echo
        echo "STORAGE"
        echo "======="

        lsblk -dn -o NAME,SIZE,TYPE,MODEL,TRAN 2>/dev/null |
            awk '$3=="disk"'

        echo
        echo "BATTERY"
        echo "======="

        BATTERY_FOUND=0

        for BAT in /sys/class/power_supply/BAT*; do

            [[ -d "$BAT" ]] || continue

            BATTERY_FOUND=1

            echo "Battery : $(basename "$BAT")"
            echo "Status  : $(cat "$BAT/status" 2>/dev/null || echo Unknown)"
            echo "Charge  : $(cat "$BAT/capacity" 2>/dev/null || echo Unknown)%"

        done

        [[ $BATTERY_FOUND -eq 1 ]] ||
            echo "No battery detected."

        echo
        echo "TEMPERATURE"
        echo "==========="

        if command_exists sensors; then
            sensors 2>/dev/null || true
        else
            echo "lm-sensors is not installed."
        fi

        echo
        echo "NETWORK"
        echo "======="

        ip -br addr 2>/dev/null || true

        echo
        echo "INTERNET"

        if command_exists ping; then

            if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
                echo "PASS - Internet reachable"
            else
                echo "CHECK - Internet not confirmed"
            fi

        fi

        echo
        echo "DIAGNOSTIC TOOLS"
        echo "================"

        command_exists smartctl &&
            echo "smartctl : available" ||
            echo "smartctl : not installed"

        command_exists nvme &&
            echo "nvme-cli : available" ||
            echo "nvme-cli : not installed"

        command_exists sensors &&
            echo "sensors  : available" ||
            echo "sensors  : not installed"

        command_exists dmidecode &&
            echo "dmidecode: available" ||
            echo "dmidecode: not installed"

    } | html_escape >> "$HTML_REPORT"

    report_end_section
}

# ============================================================================
# PDF GENERATION
# ============================================================================

generate_pdf() {

    local SUCCESS=0

    # ------------------------------------------------------------------------
    # WKHTMLTOPDF
    # ------------------------------------------------------------------------

    if command_exists wkhtmltopdf; then

        if wkhtmltopdf \
            --quiet \
            --enable-local-file-access \
            "$HTML_REPORT" \
            "$PDF_REPORT" \
            >/dev/null 2>&1; then

            SUCCESS=1

        fi

    fi

    # ------------------------------------------------------------------------
    # WEASYPRINT
    # ------------------------------------------------------------------------

    if [[ $SUCCESS -eq 0 ]] && command_exists weasyprint; then

        if weasyprint \
            "$HTML_REPORT" \
            "$PDF_REPORT" \
            >/dev/null 2>&1; then

            SUCCESS=1

        fi

    fi

    # ------------------------------------------------------------------------
    # LIBREOFFICE
    # ------------------------------------------------------------------------

    if [[ $SUCCESS -eq 0 ]] &&
       command_exists libreoffice; then

        TEMP_DIR="$(mktemp -d)"

        if libreoffice \
            --headless \
            --convert-to pdf \
            --outdir "$TEMP_DIR" \
            "$HTML_REPORT" \
            >/dev/null 2>&1; then

            GENERATED="$TEMP_DIR/Manoj_Device_Report.pdf"

            if [[ -f "$GENERATED" ]]; then
                mv "$GENERATED" "$PDF_REPORT"
                SUCCESS=1
            fi

        fi

        rm -rf "$TEMP_DIR"

    fi

    # ------------------------------------------------------------------------
    # SOFFICE
    # ------------------------------------------------------------------------

    if [[ $SUCCESS -eq 0 ]] &&
       command_exists soffice; then

        TEMP_DIR="$(mktemp -d)"

        if soffice \
            --headless \
            --convert-to pdf \
            --outdir "$TEMP_DIR" \
            "$HTML_REPORT" \
            >/dev/null 2>&1; then

            GENERATED="$TEMP_DIR/Manoj_Device_Report.pdf"

            if [[ -f "$GENERATED" ]]; then
                mv "$GENERATED" "$PDF_REPORT"
                SUCCESS=1
            fi

        fi

        rm -rf "$TEMP_DIR"

    fi

    if [[ $SUCCESS -eq 1 && -f "$PDF_REPORT" ]]; then
        return 0
    fi

    return 1
}

# ============================================================================
# CREATE COMPLETE REPORT
# ============================================================================

generate_complete_report() {

    clear

    echo
    echo -e "${CYAN}======================================================================${RESET}"
    echo -e "${WHITE}                 MANOJ BHATTA // REPORT GENERATOR${RESET}"
    echo -e "${CYAN}======================================================================${RESET}"
    echo

    # ------------------------------------------------------------------------
    # Folder is created ONLY here, when option 8 is selected.
    # ------------------------------------------------------------------------

    REPORT_TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

    REPORT_DIR="$DOWNLOADS_DIR/Manoj_Device_Report_${HOST}_${REPORT_TIMESTAMP}"

    HTML_REPORT="$REPORT_DIR/Manoj_Device_Report.html"
    PDF_REPORT="$REPORT_DIR/Manoj_Device_Report.pdf"

    # ------------------------------------------------------------------------
    # Create exactly one folder
    # ------------------------------------------------------------------------

    if ! mkdir -p "$REPORT_DIR"; then

        echo -e "${RED}ERROR: Unable to create report folder.${RESET}"
        pause_screen
        return

    fi

    # ------------------------------------------------------------------------
    # Create HTML
    # ------------------------------------------------------------------------

    echo "[1/3] Collecting device information..."

    create_html_header

    report_system
    report_device
    report_storage
    report_battery
    report_performance
    report_network
    report_quick_check

    cat >> "$HTML_REPORT" <<'EOF'

<div class="footer">

MANOJ BHATTA // LINUX DEVICE INSPECTOR

<br>

Read-only inspection report.

<br>

No hardware or system configuration was intentionally modified by this tool.

</div>

</div>

</body>
</html>
EOF

    # ------------------------------------------------------------------------
    # Generate PDF from HTML
    # ------------------------------------------------------------------------

    echo "[2/3] Generating PDF from HTML..."

    if ! generate_pdf; then

        echo
        echo -e "${YELLOW}PDF generation failed.${RESET}"
        echo
        echo "Install one of these HTML-to-PDF converters:"
        echo
        echo "  wkhtmltopdf"
        echo "  weasyprint"
        echo "  libreoffice"
        echo
        echo "The HTML report has been preserved."
        echo
        echo "No TXT file was created."
        echo

        # Ensure ownership before returning.
        chown -R \
            "$ORIGINAL_USER:$ORIGINAL_GROUP" \
            "$REPORT_DIR" 2>/dev/null || true

        chmod 755 "$REPORT_DIR" 2>/dev/null || true
        chmod 644 "$HTML_REPORT" 2>/dev/null || true

        pause_screen
        return

    fi

    # ------------------------------------------------------------------------
    # Ownership
    # ------------------------------------------------------------------------

    echo "[3/3] Applying normal-user ownership..."

    chown -R \
        "$ORIGINAL_USER:$ORIGINAL_GROUP" \
        "$REPORT_DIR" 2>/dev/null || true

    chmod 755 "$REPORT_DIR" 2>/dev/null || true
    chmod 644 "$HTML_REPORT" 2>/dev/null || true
    chmod 644 "$PDF_REPORT" 2>/dev/null || true

    # ------------------------------------------------------------------------
    # Verify exactly two files
    # ------------------------------------------------------------------------

    FILE_COUNT="$(find "$REPORT_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)"

    echo
    echo -e "${GREEN}REPORT CREATED SUCCESSFULLY${RESET}"
    echo
    echo "Folder:"
    echo "  $REPORT_DIR"
    echo
    echo "Files:"

    if [[ -f "$HTML_REPORT" ]]; then
        echo "  [OK] Manoj_Device_Report.html"
    fi

    if [[ -f "$PDF_REPORT" ]]; then
        echo "  [OK] Manoj_Device_Report.pdf"
    fi

    echo
    echo "Final file count: $FILE_COUNT"
    echo
    echo "Owner:"
    echo "  $ORIGINAL_USER:$ORIGINAL_GROUP"
    echo

    if [[ "$FILE_COUNT" -eq 2 ]]; then
        echo -e "${GREEN}Exactly two report files exist.${RESET}"
    else
        echo -e "${YELLOW}Warning: expected exactly two files.${RESET}"
    fi

    echo

    # ------------------------------------------------------------------------
    # Open report folder if desktop is available
    # ------------------------------------------------------------------------

    if command_exists xdg-open &&
       [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then

        read -r -p "Open report folder now? [y/N]: " OPEN_REPORT

        if [[ "$OPEN_REPORT" =~ ^[Yy]$ ]]; then
            sudo -u "$ORIGINAL_USER" \
                env HOME="$ORIGINAL_HOME" \
                xdg-open "$REPORT_DIR" \
                >/dev/null 2>&1 || true
        fi

    fi

    pause_screen
}

# ============================================================================
# MAIN MENU
# ============================================================================

main_menu() {

    while true; do

        clear

        echo
        echo -e "${CYAN}======================================================================${RESET}"
        echo -e "${WHITE}              MANOJ BHATTA // LINUX DEVICE INSPECTOR${RESET}"
        echo -e "${CYAN}======================================================================${RESET}"
        echo -e "${YELLOW} Host    : ${HOST}${RESET}"
        echo -e "${YELLOW} User    : ${ORIGINAL_USER}${RESET}"
        echo -e "${YELLOW} Checked : ${CHECKED_AT}${RESET}"
        echo -e "${CYAN}======================================================================${RESET}"
        echo
        echo -e "${WHITE}  1.${RESET} System Overview"
        echo -e "${WHITE}  2.${RESET} Complete Device Information"
        echo -e "${WHITE}  3.${RESET} Storage & Health"
        echo -e "${WHITE}  4.${RESET} Battery & Power"
        echo -e "${WHITE}  5.${RESET} Performance & Temperature"
        echo -e "${WHITE}  6.${RESET} Network & Connectivity"
        echo -e "${WHITE}  7.${RESET} Quick Check"
        echo -e "${GREEN}  8.${RESET} Save Complete Report"
        echo -e "${RED}  9.${RESET} Exit"
        echo
        echo -e "${CYAN}======================================================================${RESET}"
        echo

        read -r -p "Select an option [1-9]: " CHOICE

        case "$CHOICE" in

            1)
                system_overview
                ;;

            2)
                complete_device_information
                ;;

            3)
                storage_health
                ;;

            4)
                battery_power
                ;;

            5)
                performance_temperature
                ;;

            6)
                network_connectivity
                ;;

            7)
                quick_check
                ;;

            8)
                generate_complete_report
                ;;

            9)
                clear
                echo
                echo -e "${GREEN}MANOJ BHATTA // Device Inspector closed.${RESET}"
                echo
                exit 0
                ;;

            *)
                echo
                echo -e "${RED}Invalid option.${RESET}"
                sleep 1
                ;;

        esac

    done
}

# ============================================================================
# START
# ============================================================================

main_menu
