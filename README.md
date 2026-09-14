# LinuxDeviceInspector

**LinuxDeviceInspector** is a read-only Linux hardware and system inspection tool written in Bash.

It provides an interactive terminal interface for inspecting system information, CPU, memory, storage, SMART/NVMe health, battery, temperature, performance, networking, and available diagnostic utilities.

It can also generate a complete **HTML + PDF device inspection report** inside the normal user's `~/Downloads` directory.

> Built by **[Manoj Bhatta](https://github.com/mrmanojbhatta)** for Linux system inspection, hardware research, troubleshooting, and educational use.

---

## Features

* System overview
* CPU information
* Memory information
* Kernel and OS information
* BIOS / UEFI information
* Motherboard information
* DMI hardware information
* PCI device inventory
* USB device inventory
* Storage device inventory
* Filesystem usage
* Mounted filesystem information
* HDD/SSD SMART health
* NVMe health information
* Battery information
* Battery cycle count
* Estimated battery health
* AC power status
* Thermal zone information
* CPU frequency information
* CPU and memory process usage
* Network interfaces
* Network link status
* Default route
* DNS configuration
* Wireless information
* Internet connectivity check
* DNS resolution check
* Diagnostic-tool availability check
* Interactive menu
* Complete HTML report
* Complete PDF report
* Normal-user report ownership even when executed with `sudo`

---

## Menu

When the program starts, it provides the following menu:

```text
======================================================================
              MANOJ BHATTA // LINUX DEVICE INSPECTOR
======================================================================

  1. System Overview
  2. Complete Device Information
  3. Storage & Health
  4. Battery & Power
  5. Performance & Temperature
  6. Network & Connectivity
  7. Quick Check
  8. Save Complete Report
  9. Exit

======================================================================
```

### 1. System Overview

Provides a quick overview of the operating system and basic hardware.

It displays:

* Hostname
* Date and time
* Kernel
* Architecture
* Operating system
* Uptime
* CPU information
* Memory usage
* Root filesystem usage

---

### 2. Complete Device Information

Provides a more detailed hardware inventory.

It checks:

```text
System
DMI / System Hardware
BIOS / UEFI
Motherboard
CPU
Memory
PCI Devices
USB Devices
Block Devices
```

Depending on the hardware and installed utilities, information exposed by firmware and Linux may include model names, serial numbers, firmware information, memory modules, PCI devices, USB devices, and storage information.

---

### 3. Storage & Health

Designed for storage inspection.

It checks:

```text
Block Devices
Filesystem Usage
Mounted Filesystems
SMART Disk Health
NVMe Health
```

The storage section uses `lsblk`, `df`, `findmnt`, `smartctl`, and `nvme` when available.

### SMART

If `smartctl` is installed, the program checks supported physical disks for health information.

Relevant information may include:

```text
SMART overall health
Temperature
Percentage Used
Available Spare
Critical Warning
Power On Hours
Unsafe Shutdowns
Media/Data Integrity
Error Information
Reallocated sectors
Pending sectors
Uncorrectable sectors
```

The exact information depends on the storage device.

### NVMe

If `nvme-cli` is installed, the program uses:

```bash
nvme smart-log
```

The script intentionally does **not** run:

```bash
nvme id-ctrl
```

This prevents unnecessary NVMe controller-identification output such as:

```text
IDENTIFY CONTROLLER
vid
ssvid
```

The NVMe section focuses on health information such as:

```text
critical_warning
temperature
available_spare
percentage_used
data_units_read
data_units_written
host_read_commands
host_write_commands
controller_busy_time
power_cycles
power_on_hours
unsafe_shutdowns
media_errors
num_err_log_entries
warning_temp_time
critical_comp_time
```

---

### 4. Battery & Power

Designed especially for laptops and other Linux systems that expose battery information.

It checks:

* Battery manufacturer
* Battery model
* Battery serial
* Battery technology
* Battery status
* Current capacity
* Cycle count
* Estimated battery health
* AC/mains power status
* Thermal zones

Battery information is read from:

```text
/sys/class/power_supply/
```

The tool can calculate an estimated battery health percentage when Linux exposes design and current full-capacity values.

For example:

```text
Estimated Health = Full Capacity / Design Capacity × 100
```

If no battery is exposed by the system:

```text
No battery detected.
```

---

### 5. Performance & Temperature

Provides a lightweight snapshot of current system activity.

It checks:

* System uptime
* Load average
* CPU information
* Memory usage
* Swap
* CPU frequency
* Temperature sensors
* Top CPU processes
* Top memory processes

CPU frequency information is read from Linux CPU frequency interfaces when available.

If `lm-sensors` is installed, the program also uses:

```bash
sensors
```

The process lists are generated using:

```bash
ps
```

This is a system snapshot, not a benchmark or stress test.

---

### 6. Network & Connectivity

Provides basic network information and connectivity checks.

It checks:

```text
Network Interfaces
Network Links
Default Route
DNS
Wireless
Network Hardware
Internet Connectivity
DNS Resolution
```

The program uses tools such as:

```bash
ip
resolvectl
iw
lspci
ping
getent
```

Internet connectivity is tested against:

```text
1.1.1.1
```

DNS resolution is tested using:

```text
example.com
```

These tests only confirm whether connectivity/resolution worked at the time of execution.

---

### 7. Quick Check

Provides a compact overview for quickly checking the current machine.

It includes:

```text
Operating System
Kernel
Architecture
CPU
Memory
Storage
Battery
Temperature
Network
Internet Connectivity
Diagnostic Tools
```

It also checks whether these utilities are available:

```text
smartctl
nvme-cli
sensors
dmidecode
```

For a fast inspection, this is the recommended menu option.

---

### 8. Save Complete Report

Generates the complete inspection report.

The report is stored under:

```text
~/Downloads/
```

The directory uses this format:

```text
Manoj_Device_Report_<HOST>_<TIMESTAMP>/
```

Example:

```text
~/Downloads/Manoj_Device_Report_my-pc_20260914_131200/
```

The directory contains exactly two final report files:

```text
Manoj_Device_Report.html
Manoj_Device_Report.pdf
```

No TXT report is intentionally created.

---

## Report Structure

The generated report contains:

```text
Manoj_Device_Report_<HOST>_<TIMESTAMP>/
│
├── Manoj_Device_Report.html
└── Manoj_Device_Report.pdf
```

The HTML report contains the complete inspection results in a structured interface.

The PDF is generated from the HTML report.

---

## PDF Generation

The script automatically looks for a supported HTML-to-PDF converter.

It attempts:

```text
1. wkhtmltopdf
2. weasyprint
3. libreoffice
4. soffice
```

The first working converter is used.

If PDF generation fails, the HTML report is preserved.

The script does not create a TXT fallback.

---

## Requirements

The basic script uses standard Linux utilities.

For the most complete hardware inspection, install:

```bash
sudo apt update
sudo apt install dmidecode pciutils usbutils smartmontools nvme-cli lm-sensors
```

For PDF generation, install at least one supported converter.

For example:

```bash
sudo apt install wkhtmltopdf
```

or:

```bash
sudo apt install libreoffice
```

Package names may differ between Linux distributions.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/mrmanojbhatta/LinuxDeviceInspector.git
```

Enter the directory:

```bash
cd LinuxDeviceInspector
```

Make the script executable:

```bash
chmod +x linuxdeviceinspector.sh
```

Run it:

```bash
./linuxdeviceinspector.sh
```

The script automatically requests `sudo` when necessary.

You can also run it directly with:

```bash
sudo ./linuxdeviceinspector.sh
```

---

## Quick Start

For a normal installation:

```bash
git clone https://github.com/mrmanojbhatta/LinuxDeviceInspector.git
cd LinuxDeviceInspector
chmod +x linuxdeviceinspector.sh
./linuxdeviceinspector.sh
```

Then select:

```text
7
```

for a quick inspection.

For the complete HTML + PDF report:

```text
8
```

---

## Why Does the Script Use sudo?

Some hardware information requires elevated privileges.

For example:

```bash
dmidecode
```

may require root access to read firmware/DMI information.

The script therefore detects whether it is already running as root.

If not, it automatically re-executes itself through:

```bash
sudo
```

This allows privileged diagnostic information to be collected.

---

## Normal User Ownership

The report system is designed to avoid leaving generated files owned by `root`.

When the program is launched by a normal user and escalates through `sudo`, it remembers the original user and home directory.

Reports are then created in:

```text
/home/<user>/Downloads/
```

and ownership is restored to the normal user.

The intended result is:

```text
user:user
```

rather than:

```text
root:root
```

This makes the generated reports easier to open, edit, move, or delete from the normal desktop session.

---

## Read-Only Design

LinuxDeviceInspector is designed as a **read-only inspection tool**.

It reads information exposed by Linux, firmware, hardware interfaces, and installed diagnostic utilities.

It does not intentionally:

```text
Format disks
Create partitions
Delete partitions
Create filesystems
Modify BIOS/UEFI
Flash firmware
Modify hardware configuration
Run disk repair
Delete user files
Perform disk write tests
```

Storage health commands such as SMART and NVMe health queries are diagnostic operations intended to retrieve information from the device.

Always review any script before executing it with root privileges.

---

## What the Tool Can Detect

Depending on the hardware and Linux environment, the tool can expose information about:

```text
Operating System
Kernel
CPU
RAM
Motherboard
BIOS / UEFI
PCI Devices
USB Devices
HDD
SSD
NVMe
Filesystems
Mount Points
Battery
AC Power
Thermal Sensors
CPU Frequency
Running Processes
Network Interfaces
Wireless Interfaces
DNS
Routing
Internet Connectivity
```

The exact fields available depend on the system.

---

## Important: Missing Information

Not every Linux system exposes every hardware field.

You may see:

```text
Unknown
```

or:

```text
information unavailable
```

or:

```text
not installed
```

This does not automatically indicate a hardware problem.

Possible reasons include:

* Hardware does not expose the information
* Firmware does not provide the information
* Kernel limitations
* Unsupported hardware
* Missing diagnostic utility
* Permission restrictions
* Virtualized hardware
* Vendor-specific implementation

LinuxDeviceInspector reports available information rather than inventing values.

---

## Hardware Authenticity Disclaimer

LinuxDeviceInspector can help inspect a used or second-hand computer, but it does **not** certify hardware authenticity.

For example, if the tool reports:

```text
Model: Example SSD
```

that does not prove that the SSD was installed by the original manufacturer.

Likewise, DMI information may sometimes be incomplete, generic, modified, or inaccurate.

For second-hand device inspection, combine this tool with:

* Physical inspection
* Manufacturer documentation
* SMART/NVMe health
* Firmware information
* Storage information
* Battery information
* Appropriate hardware tests

---

## Privacy Warning

The generated report may contain sensitive machine information.

Depending on the system, the report may contain:

```text
Hostname
Hardware Serial Numbers
Storage Serial Numbers
Battery Serial Numbers
Filesystem UUIDs
IP Addresses
Network Information
Process Information
Hardware Identifiers
BIOS Information
```

Before sharing the HTML or PDF publicly, review and redact sensitive information.

Do not upload an unredacted report to GitHub, social media, forums, Discord, or other public platforms unless you intentionally want those details to be public.

---

## Virtual Machines

The tool can run inside virtual machines.

However, the reported hardware may represent virtualized hardware rather than the physical host.

For example:

```text
CPU
RAM
Storage
PCI devices
DMI
Network hardware
```

may not represent the actual physical components.

For physical hardware inspection, run the tool directly on the physical Linux installation when possible.

---

## Diagnostic Tools

The following utilities provide additional information when installed:

| Utility                      | Purpose                              |
| ---------------------------- | ------------------------------------ |
| `dmidecode`                  | DMI / BIOS / motherboard information |
| `pciutils` / `lspci`         | PCI device information               |
| `usbutils` / `lsusb`         | USB device information               |
| `smartmontools` / `smartctl` | HDD/SSD SMART information            |
| `nvme-cli` / `nvme`          | NVMe health information              |
| `lm-sensors` / `sensors`     | Temperature and sensor information   |
| `iw`                         | Wireless interface information       |
| `iproute2` / `ip`            | Network configuration                |
| `procps` / `ps`              | Process information                  |

---

## Troubleshooting

### `dmidecode` not installed

```bash
sudo apt install dmidecode
```

### `lspci` not installed

```bash
sudo apt install pciutils
```

### `lsusb` not installed

```bash
sudo apt install usbutils
```

### `smartctl` not installed

```bash
sudo apt install smartmontools
```

### `nvme` not installed

```bash
sudo apt install nvme-cli
```

### `sensors` not installed

```bash
sudo apt install lm-sensors
```

### PDF is not generated

Install one of the supported converters:

```bash
sudo apt install wkhtmltopdf
```

or:

```bash
sudo apt install libreoffice
```

Then select:

```text
8. Save Complete Report
```

again.

---

## Example Workflow

### Quick device check

```text
Start
  ↓
7. Quick Check
  ↓
Review basic system status
  ↓
Return to menu
```

### Storage inspection

```text
Start
  ↓
3. Storage & Health
  ↓
Review disks
  ↓
Review SMART
  ↓
Review NVMe health
```

### Complete report

```text
Start
  ↓
8. Save Complete Report
  ↓
Collect system information
  ↓
Collect hardware information
  ↓
Collect storage information
  ↓
Collect battery information
  ↓
Collect performance information
  ↓
Collect network information
  ↓
Generate HTML
  ↓
Generate PDF
  ↓
Apply normal-user ownership
  ↓
HTML + PDF
```

---

## Project Structure

```text
LinuxDeviceInspector/
│
├── linuxdeviceinspector.sh
└── README.md
```

Generated reports are stored outside the repository:

```text
~/Downloads/
```

---

## Use Cases

LinuxDeviceInspector can be useful for:

* Linux troubleshooting
* Laptop inspection
* Desktop inspection
* Second-hand computer checking
* Storage health inspection
* Battery inspection
* Hardware inventory
* System administration
* Linux learning
* Hardware research
* Creating device reports
* Technical documentation
* Educational demonstrations

---

## Limitations

LinuxDeviceInspector is an inspection and reporting tool.

It does not currently provide:

```text
CPU Stress Testing
GPU Benchmarking
RAM Stress Testing
Disk Write Benchmarking
Filesystem Repair
Disk Repair
SMART Self-Tests
NVMe Self-Tests
Port Scanning
Vulnerability Scanning
Malware Detection
Firmware Authenticity Certification
Hardware Authenticity Certification
```

Its purpose is to collect and organize information already exposed by the operating system and supported diagnostic utilities.

---

## Security Philosophy

The project follows a simple principle:

```text
READ
 ↓
INSPECT
 ↓
FILTER
 ↓
DISPLAY
 ↓
REPORT
```

The objective is useful system information without unnecessary command output.

For example, the NVMe inspection focuses on health information instead of dumping the complete NVMe controller-identification data.

---

## Contributing

Contributions and improvements are welcome.

If you want to contribute:

```bash
git clone https://github.com/mrmanojbhatta/LinuxDeviceInspector.git
cd LinuxDeviceInspector
```

Create a branch:

```bash
git checkout -b feature/your-feature
```

Test your changes on a real Linux system.

Then commit:

```bash
git add .
git commit -m "Add your feature"
```

Push your branch:

```bash
git push origin feature/your-feature
```

Then open a Pull Request.

### Contribution guidelines

Please keep contributions:

* Read-only where possible
* Safe for normal Linux systems
* Compatible with Bash
* Graceful when optional commands are missing
* Free from unnecessary output
* Clearly documented

Do not add destructive operations without a clear project requirement and explicit documentation.

---

## Bug Reports

If you discover a problem, include:

```text
Linux Distribution:
Kernel:
Architecture:
Hardware:
Shell:
Command / Menu Option:
Expected Result:
Actual Result:
Error:
```

Before posting logs publicly, remove sensitive information such as:

```text
Serial Numbers
MAC Addresses
Private IP Addresses
Filesystem UUIDs
Battery Serial Numbers
```

---

## Author

**Manoj Bhatta**

GitHub:

https://github.com/mrmanojbhatta

Repository:

https://github.com/mrmanojbhatta/LinuxDeviceInspector

---

## Project

**LinuxDeviceInspector**

A practical Bash-based Linux device inspection and reporting utility.

```text
MANOJ BHATTA // LINUX DEVICE INSPECTOR

Inspect.
Understand.
Document.
```

---

## License

This repository currently does not specify a license.

If you want others to legally reuse, modify, and redistribute the project, add an appropriate open-source license to the repository.

For example, if you choose MIT:

```text
LICENSE
```

should be added to the repository with the official MIT License text.

Until a license is added, the default copyright rules generally apply to the repository's original code.
