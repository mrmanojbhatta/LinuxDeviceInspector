# LinuxDeviceInspector

**LinuxDeviceInspector** is an open-source Linux hardware inspection and device information tool created by **Manoj Bhatta**.

It is designed to help Linux users inspect their system hardware, storage, battery, temperature, network devices, and other important device information in an organized way.

The tool is especially useful when you are **buying a new or second-hand laptop that already has Linux installed**. Instead of relying only on the specifications provided by a seller, you can use LinuxDeviceInspector to inspect what the Linux system actually detects.

**Created by:** Manoj Bhatta
**Website:** manoj-bhatta.com.np

## About

When buying a laptop, the specifications shown by a seller, advertisement, sticker, or online listing may not provide the complete technical picture.

LinuxDeviceInspector gives you a practical way to inspect the hardware detected by Linux.

It can help you check:

* Manufacturer and model
* CPU and architecture
* RAM
* Motherboard and firmware information
* PCI devices
* USB devices
* SSD/HDD storage
* NVMe health information
* SMART information
* Battery condition
* Battery capacity
* Temperature sensors
* Network adapters
* Wi-Fi hardware
* Ethernet hardware
* Filesystems and disk usage
* Basic network and DNS connectivity

The project is **open source** and intended for learning, system inspection, troubleshooting, and practical laptop checking.

## Why This Tool?

If you are buying a laptop with Linux already installed, you can run this tool before purchasing it.

For example, a seller may advertise:

```text
Core i5
8 GB RAM
512 GB SSD
Good Battery
```

LinuxDeviceInspector lets you inspect the system instead of depending only on those claims.

You can check the detected CPU, memory, storage, battery information, hardware devices, temperatures, and other available system information.

This is particularly useful for:

* New laptop inspection
* Second-hand laptop inspection
* Refurbished laptop inspection
* Linux hardware identification
* Storage health checking
* Battery condition checking
* Basic thermal inspection
* Technical documentation

## Installation

Clone the repository:

```bash
git clone <repository-url>
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

For additional hardware information, install the recommended diagnostic utilities:

```bash
sudo apt update
sudo apt install dmidecode pciutils usbutils smartmontools nvme-cli lm-sensors
```

## Characteristics

LinuxDeviceInspector is designed to be:

* **Open source**
* **Read-only**
* **Linux-focused**
* **Buyer-oriented**
* **Terminal-based**
* **Organized by inspection categories**
* **Focused on useful hardware information**
* **Suitable for new and second-hand laptop inspection**
* **Capable of generating HTML and PDF reports**
* **Designed to avoid unnecessary raw hardware output**

The tool does not intentionally modify hardware configuration or system settings.

## Features

### 1. System Overview

Quickly inspect the major characteristics of the Linux system:

* Operating system
* Kernel
* Architecture
* Hostname
* CPU
* Memory
* Disk usage
* Basic system information

### 2. Complete Device Information

Inspect detailed hardware information:

* System manufacturer
* System model
* BIOS/UEFI
* CPU
* PCI devices
* USB devices
* Block devices
* Filesystems
* Mount points

### 3. Storage & Health

Inspect available storage information:

* SSD/HDD
* NVMe devices
* Capacity
* Model information
* SMART information
* NVMe health information
* Temperature
* Power-on information when available
* Error information when available

The exact information depends on the storage hardware and permissions available to Linux.

### 4. Battery & Power

For laptops, inspect available battery information:

* Battery presence
* Battery capacity
* Design capacity
* Full-charge capacity
* Charging state
* Estimated battery health
* Power information

Battery health is an estimate based on information exposed by the operating system.

### 5. Performance & Temperature

Inspect basic system performance and thermal information:

* CPU information
* Memory usage
* System load
* Temperature sensors
* Sensor readings
* Running processes

This is an inspection tool, not a benchmark.

### 6. Network & Connectivity

Inspect detected network hardware and basic connectivity:

* Network interfaces
* IP information
* Wi-Fi information when available
* Ethernet information
* Basic internet connectivity
* DNS resolution

### 7. Quick Check

Perform a faster inspection of important system components without generating a complete report.

### 8. Save Complete Report

Generate a complete organized report containing the inspection results.

The report is saved under:

```text
~/Downloads/
```

The final report directory contains:

```text
Manoj_Device_Report.html
Manoj_Device_Report.pdf
```

Only these two final report files are generated.

## Open Source

LinuxDeviceInspector is an **open-source project created by Manoj Bhatta**.

The project is intended to be useful for Linux users, students, developers, system administrators, cybersecurity learners, technicians, and anyone who wants to understand the hardware detected by their Linux system.

You are encouraged to inspect the source code, learn from it, improve it, and contribute to the project according to the repository's licensing terms.

## Created By

**Manoj Bhatta**

Cybersecurity Enthusiast | Ethical Hacker | Security Researcher | OSINT Researcher | Full-Stack Web Developer

Website:

**manoj-bhatta.com.np**

Project:

**LinuxDeviceInspector**

The project is part of Manoj Bhatta's work in Linux, cybersecurity, system inspection, hardware analysis, and open-source tooling.

## Important Limitation

LinuxDeviceInspector reports information that Linux and available hardware interfaces expose.

It cannot prove that:

* Every component is factory-original
* A component has never been replaced
* A laptop has never been repaired
* A seller's specifications are completely truthful
* The hardware has no physical damage
* The device will not fail in the future

For a serious laptop purchase, combine the report with physical inspection, serial/warranty verification where appropriate, display testing, keyboard testing, port testing, charger testing, and other hardware checks.

LinuxDeviceInspector is a **hardware inspection tool**, not a hardware authenticity guarantee.

## Author

**Manoj Bhatta**

Website: **manoj-bhatta.com.np**

Open-source project: **LinuxDeviceInspector**
