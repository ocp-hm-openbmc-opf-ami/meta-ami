# OpenBMC

OpenBMC is a Linux distribution for management controllers used in devices such
as servers, top of rack switches or RAID appliances. It uses
[Yocto](https://www.yoctoproject.org/),
[OpenEmbedded](https://www.openembedded.org/wiki/Main_Page),
[systemd](https://www.freedesktop.org/wiki/Software/systemd/), and
[D-Bus](https://www.freedesktop.org/wiki/Software/dbus/) to allow easy
customization for your platform.

## Setting up your OpenBMC project

### 1) Prerequisite

See the
[Yocto documentation](https://docs.yoctoproject.org/ref-manual/system-requirements.html#required-packages-for-the-build-host)
for the latest requirements

#### Ubuntu

```sh
sudo apt install git gcc g++ make file wget \
    gawk diffstat bzip2 cpio chrpath zstd lz4 bzip2 git-lfs
```

#### Fedora

```sh
sudo dnf install git python3 gcc g++ gawk which bzip2 chrpath cpio \
    hostname file diffutils diffstat lz4 wget zstd rpcgen patch git-lfs
```

### 2) Download and build

### 2.1 AST2600EVB
```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.2 AST2700EVB
```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2700/meta-ast2700/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.3 Nuvoton Arbel

```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-nuvoton/meta-evb-npcm845/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.4 Agilex-3

```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-altera.git
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-altera/meta-agilex3/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.5 Agilex-5

```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-altera.git
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-altera/meta-agilex5/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.6 FVP

```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-arm/meta-evb-fvp-base/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.7 NXP FRDM i.MX93

```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-nxp/meta-imx93/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.8 NXP i.MX95 EVK

```sh
git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-nxp/meta-imx95/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

##  DevKit

The AMI DevKit is a development platform for building and testing BMC firmware. It helps developers check how the BMC works with server hardware, including monitoring sensors and controlling supported devices.The sensor board provides hardware signals that make these functions available for testing.

### Sensor Board

The AMI S997 sensor board provides interfaces for:

- Temperature, voltage, and current monitoring
- Fan speed readings and PWM fan control
- ADC, GPIO, and discrete inputs
- LEDs, buttons, DIP switches, and a 7-segment display
- SGPIO and backplane management

These interfaces let developers test sensor monitoring and hardware control during firmware development. The features available depend on the DevKit platform and firmware configuration.

## Build Instructions

Build instructions are provided below for the supported SoCs: AST2600, AST2700, and Arbel.

###  Devkit-2600

```
git clone --branch DevKit_AST2600 https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone --branch DevKit_AST2600 https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone --branch DevKit_AST2600 https://github.com/ocp-hm-openbmc-opf-ami/meta-ami.git meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-ami-devkit/conf/templates/default . openbmc-env 
bitbake obmc-phosphor-image
```

###  Devkit-2700

```
git clone --branch DevKit_AST2700 https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone --branch DevKit_AST2700 https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone --branch DevKit_AST2700 https://github.com/ocp-hm-openbmc-opf-ami/meta-ami.git meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-amidevkit-2700/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

###  Devkit-arbel

```
git clone --branch DevKit_Arbel https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone --branch DevKit_Arbel https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone --branch DevKit_Arbel https://github.com/ocp-hm-openbmc-opf-ami/meta-ami.git meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-aminuvton/conf/templates/default . openbmc-env 
bitbake obmc-phosphor-image
```

Please refer to [ocp-hm-openbmc-opf-ami/docs](https://github.com/ocp-hm-openbmc-opf-ami/docs)
for more information.
