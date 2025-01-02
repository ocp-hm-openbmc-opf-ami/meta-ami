# MegaRAC OneTree
- MegaRAC OneTree is AMI’s next generation BMC firmware solution following MegaRAC SP-X 13.
- Based on OpenBMC from linux foundation. All the SDK from SoC and Si vendors are integrated into OneTree as single stack to support multi SoC and multi silicon.
- Built on pervasive, open-source industry tools, architecture, and standards such as Yocto, BitBake, OpenEmbedded, D-bus etc.. 
- Enriched with added core feature sets for platform manageability
- Enhanced by AMI advanced technologies such as Expansion Packs (EP) and Silicon Packs (SiP)
- Backed by AMI’s premium customer support

### Important Information
- After Stable release features migrated into the main branch, the tag "OneTree-X.X" is created in the main repositories. The tag is just providing the information "when the milestone New feature/feature enhancement migration Finished" Only. The latest main branch always provides the latest Bug fixed and Feature enhancement. **Please take the latest main Branch for the project development.**

### 1) Prerequisite

See the [Yocto documentation](https://docs.yoctoproject.org/ref-manual/system-requirements.html#required-packages-for-the-build-host)
for the latest requirements

```sh
The OneTree Development environment, bash shell has to be the default shell.
    Give the following command to use bash as the default shell.
    $ sudo dpkg-reconfigure dash
    Select No in the appearing dialog and press Enter
```

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
- git clone https://git.ami.com/core/ami-bmc/base-tech/openbmc onetree; cd onetree
- git clone https://git.ami.com/core/ami-bmc/one-tree/core/meta-core
- git clone  https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami
```

### 3) OneTree Core EGS Build Instruction
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/egs meta-core/meta-egs
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-intel meta-core/meta-intel
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-core/meta-egs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```
### 4) OneTree Core BHS Build Instruction
 ```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/bhs meta-core/meta-bhs
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-intel meta-core/meta-intel
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-core/meta-bhs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```
### 5) OneTree Core AST2600EVB Build Instruction
```
- meta-ami/github-gitlab-url.sh
- Add the other meta layer and features (optional)
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```

### 6) OneTree Intel Silicon and Expansion Pack (EGS)
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/egs meta-core/meta-egs
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted meta-core/meta-restricted
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-intel meta-core/meta-intel 
- meta-ami/github-gitlab-url.sh
- Add meta-resticted layer into meta-core/meta-egs/conf/templates/default/bblayers.conf.sample
- Enable the needed Si and EP features in meta-core/meta-restricted/conf/layer.conf (Uncomment IMAGE_INSTALL and/or EXTRA_IMAGE_FEATURES)
- TEMPLATECONF=meta-core/meta-egs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```
### 7) OneTree Intel Silicon and Expansion Pack (BHS)
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/bhs meta-core/meta-bhs
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted meta-core/meta-restricted
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-intel meta-core/meta-intel 
- meta-ami/github-gitlab-url.sh
- Add meta-resticted layer into meta-core/meta-bhs/conf/templates/default/bblayers.conf.sample
- Enable the needed Si and EP features in meta-core/meta-restricted/conf/layer.conf (Uncomment IMAGE_INSTALL and/or EXTRA_IMAGE_FEATURES)
- TEMPLATECONF=meta-core/meta-bhs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```

### 8) OneTree AMI Exapnsion Pack
```
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/egs meta-core/meta-egs (For EGS)
- git clone  https://git.ami.com/core/ami-bmc/one-tree/intel/bhs meta-core/meta-bhs (For BHS)
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/nic meta-ami/recipes-ami/nic (For NIC EP)
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/nvme meta-ami/recipes-ami/nvme (For NVMe EP)
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/raid/raid-brcm meta-ami/recipes-ami/raid-brcm (For BRCM Raid EP)
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/redfish meta-ami/recipes-ami/redfish (For Redfish EP)
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/firmware-update meta-ami/recipes-ami/fwupdate (For FirmwareUpdate EP)
- meta-ami/github-gitlab-url.sh
- Enable the needed AMI EP features in meta-ami/conf/layer.conf (Uncomment IMAGE_INSTALL)
- TEMPLATECONF=meta-core/meta-egs/conf/templates/default . openbmc-env (For EGS)
- TEMPLATECONF=meta-core/meta-bhs/conf/templates/default . openbmc-env (For BHS)
- bitbake intel-platforms
```

### 9) OneTree Core Arbel Build Instruction
```
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-nuvoton/meta-evb-npcm845/conf/templates/default . openbmc-env 
- bitbake obmc-phosphor-image
```

### 10) OneTree Core AST2700EVB Build Instruction
```
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2700/meta-ast2700/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```

### 11) OT Core AST2750 DCSCM Build Instruction
```
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2700/meta-ast2700-pfr/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```

### Notes
- By default root user is disabled in the stack except AST2600EVB
- uncomment EXTRA_IMAGE_FEATURES += "debug-tweaks" in build/conf/local.conf to enable the root user access

