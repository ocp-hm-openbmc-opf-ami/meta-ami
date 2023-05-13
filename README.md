# MegaRAC OneTree
- MegaRAC OneTree (OT) is AMI’s next generation BMC firmware solution following MegaRAC SP-X 13.
- Based on Intel and Linux Foundation OpenBMC stack
- Built on pervasive, open-source industry tools, architecture, and standards such as Yocto, BitBake, OpenEmbedded, D-bus etc.. 
- Enriched with added core feature sets for platform manageability
- Enhanced by AMI advanced technologies such as Expansion Packs (EP) and Silicon Packs (SiP)
- Backed by AMI’s premium customer support

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
### 2) Common Repository for all the OneTree Build
```
- git clone https://git.ami.com/core/ami-bmc/base-tech/firmware.bmc.openbmc.yocto.openbmc onetree; cd onetree
- git clone https://git.ami.com/core/ami-bmc/one-tree/core/openbmc-meta-intel
- git clone  https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami
```

### 3) OT Core EGS Build Instruction
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/egs openbmc-meta-intel/meta-egs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=openbmc-meta-intel/meta-egs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```
### 4) OT Core BHS Build Instruction
 ```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/bhs openbmc-meta-intel/meta-bhs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=openbmc-meta-intel/meta-bhs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```
### 5) OT Core AST2600EVB Build Instruction
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/egs openbmc-meta-intel/meta-egs
- meta-ami/github-gitlab-url.sh
- Add the features into meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/layer.conf
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/templates/default . openbmc-env
- bitbake obmc-phopshor-image
```

### 6) OT Intel Silicon and Expansion Pack
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/egs openbmc-meta-intel/meta-egs
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted openbmc-meta-intel/meta-restricted
- meta-ami/github-gitlab-url.sh
- Add meta-resticted layer into openbmc-meta-intel/meta-egs/conf/templates/default/bblayers.conf.sample
- Enable the needed Si and EP features in openbmc-meta-intel/meta-restricted/conf/layer.conf (Uncomment IMAGE_INSTALL and/or EXTRA_IMAGE_FEATURES)
- TEMPLATECONF=openbmc-meta-intel/meta-egs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```

### 7) OT Intel Silicon and Expansion Pack
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/nic meta-ami/recipes-ami/nic (For NIC EP)
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/nvme meta-ami/recipes-ami/nvme (For NVMe EP)
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/raid-brcm meta-ami/recipes-ami/raid-brcm (For BRCM Raid EP)
- meta-ami/github-gitlab-url.sh
- Enable the needed AMI EP features in meta-ami/conf/layer.conf (Uncomment IMAGE_INSTALL)
- TEMPLATECONF=openbmc-meta-intel/meta-egs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```
### Notes
- By default root user is disabled in the stack except AST2600EVB
- uncomment EXTRA_IMAGE_FEATURES += "debug-tweaks" in build/conf/local.conf to enable the root user access

