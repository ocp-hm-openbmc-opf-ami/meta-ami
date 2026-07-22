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
    gawk diffstat bzip2 cpio chrpath zstd lz4 bzip2
```

#### Fedora

```sh
sudo dnf install git python3 gcc g++ gawk which bzip2 chrpath cpio \
    hostname file diffutils diffstat lz4 wget zstd rpcgen patch
```

### 2) Download and build

### 2.1 AST2600EVB
```sh
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.2 AST2700EVB
```sh
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2700/meta-ast2700/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

### 2.3 Nuvoton Arbel

```sh
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/meta-core
git clone --branch CE-AMI202607 https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
meta-ami/github-gitlab-url.sh
TEMPLATECONF=meta-ami/meta-evb/meta-evb-nuvoton/meta-evb-npcm845/conf/templates/default . openbmc-env
bitbake obmc-phosphor-image
```

Please refer to [ocp-hm-openbmc-opf-ami/docs](https://github.com/ocp-hm-openbmc-opf-ami/docs)
for more information.