# MegaRAC OpenEdition


MegaRAC OpenEdition is a hardened, production version based on OpenBMC. OpenBMC is a Linux distribution for management controllers used in devices such
as servers, top of rack switches or RAID appliances. 

It uses
[Yocto](https://www.yoctoproject.org/),
[OpenEmbedded](https://www.openembedded.org/wiki/Main_Page),
[systemd](https://www.freedesktop.org/wiki/Software/systemd/), and
[D-Bus](https://www.freedesktop.org/wiki/Software/dbus/) to allow easy
customization for your platform.

https://www.ami.com/open-source/#open-edition

## Setting up your OpenBMC project

### 1) Prerequisite

See the [Yocto documentation](https://docs.yoctoproject.org/ref-manual/system-requirements.html#required-packages-for-the-build-host)
for the latest requirements

#### Ubuntu
```
$ sudo apt install git python3-distutils gcc g++ make file wget \
    gawk diffstat bzip2 cpio chrpath zstd lz4 bzip2
```

#### Fedora
```
$ sudo dnf install git python3 gcc g++ gawk which bzip2 chrpath cpio
hostname file diffutils diffstat lz4 wget zstd rpcgen patch
```

### 2) Download the source
```
git clone https://git.ami.com/core/oe/common/firmware.bmc.openbmc.yocto.openbmc openbmc; cd openbmc
git clone https://git.ami.com/core/oe/common/openbmc-meta-intel-egs openbmc-meta-intel
git clone https://git.ami.com/core/oe/common/meta-ami
sh meta-ami/meta-common/github-gitlab-url.sh
```

### 3) How to Build ArcherCity
```
TEMPLATECONF=openbmc-meta-intel/meta-egs/conf/templates/default . openbmc-env
bitbake intel-platforms
```

### 4) How to Build AST2600EVB
```
TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```
### 5) How to Enable Full Extension Packs
```
Step 1: Uncomment IMAGE_INSTALL in meta-ami/conf/layer.conf
Step 2: Enable PFR in openbmc-meta-intel/meta-egs/conf/templates/default/local.conf.sample 
Step 3: Enable egs-image-common in openbmc-meta-intel/meta-egs/recipes-intel/images/intel-platforms.bbappend 
Step 4: Enable obmc-phosphor-image-restricted in openbmc-meta-intel/meta-restricted/recipes-intel/images/intel-platforms.bbappend 
Step 5: Rebuild the image
 ```
## Features of OpenEdition

** Feature List**
* IPMI 2.0
* DCMI 1.5
* IPMI LAN Interface
* IPMI KCS Interface
* IPMI SOL and SOLSSH
* Sensor
* SEL
* FRU 
* LED
* IPMB
* Power Control
* User Management
* Certificate Management
* OpenLDAP/AD Support
* Enhanced Password Policy Support
* Post Code Manager
* Watchdog Support (HW and IPMI)
* NTP and Time Zone configuration Support
* Factory Reset
* Auto Disable Factory Default Login Credentials
* Memory ECC Support
* Thermal Management
* Diagnostics, fault detection and analysis 
* Thermal Management
* ARP/GARP Support
* IPv6
* VLAN
* Debug Log Collector
* DNS and mDNS Support
* Redfish
* ASD
* ACD
* CPU Crash Log
* Memory Resilance Technology (MRT)
* Host Interface Support
* Firmware Update
* CUPS
* Telemetry
* Service configuration
* iKVM
* Virtual Media redirection over HTML5
* Remote Media redirection - NFS, CIFS, HTTPS
* Embedded WebUI
* PEF and Alert
* Power Optimization through NM
* Tools (I2c, gpio, ADC, PWM)
* QA Automation
* MCTP and Binding (I2c, PCIe)
* NIC Management
* NVMe-Basic, NVMe-MI
* Seamless update

## Finding out more

Dive deeper into OpenBMC by opening the
[docs](https://github.com/openbmc/docs) repository.

