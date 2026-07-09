
#### Agenda

* [Chapter 1 Prerequisite](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_Old.md?ref_type=heads#chapter-1-prerequisite)

* [Chapter 2 Core CRB / EVB Build Instruction](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_Old.md?ref_type=heads#chapter-2-crb--evb-build-instruction)

    [Step 1) Common Repository for all the OneTree Build](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_Old.md?ref_type=heads#step-1-common-repository-for-all-the-onetree-build)

    [Step 2) CRB/EVB Specific Repositories And Build Instruction](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_Old.md?ref_type=heads#step-2-crbevb-specific-repositories-and-build-instruction)

    -[AST2600EVB](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_Old.md?ref_type=heads#ast2600evb)

    -[AST2700EVB](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#ast2700evb)

    -[AST2700EVB DCSCM with Intel AvenCity CRB](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_Old.md?ref_type=heads#ast2700evb-dcscm-with-intel-avencity-crb)

    -[Intel EGS](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#intel-egs)

    -[Intel BHS](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#intel-bhs)

    -[NVIDIA MGX CG1(GH200)](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#nvidia-mgx-cg1gh200)

    -[NVIDIA MGX C2 (Grace Superchip)](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#nvidia-mgx-c2-grace-superchip)

    -[AMD Chalupa](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#amd-chalupa)

    -[Ampere Mt. Mitchell](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#ampere-mt-mitchell)

    -[Nuvoton Arbel](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#nuvoton-arbel)

* [Chapter 3 Extension Pack configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#chapter-3-extension-pack-configuration)

    -[Redfish Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#redfish-expansion-pack-configuration)

    -[BRCM RAID Management Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#brcm-raid-management-expansion-pack-configuration)

    -[MSCC RAID Management Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#mscc-raid-management-expansion-pack-configuration)

    -[Intel ACD Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#intel-acd-expansion-pack-configuration)

    -[Intel ASD Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#intel-asd-expansion-pack-configuration)

    -[Intel MRT Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#intel-mrt-expansion-pack-configuration)

    -[Intel PFR Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#intel-pfr-expansion-pack-configuration)

    -[GPGPU Management Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#gpgpu-management-expansion-pack-configuration)

    -[Firmware Update Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#firmware-update-expansion-pack-configuration)

    -[AMD Remote Debug Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#amd-remote-debug-expansion-pack-configuration)

    -[NIC Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#nic-expansion-pack-configuration)

    -[NVMe Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#nvme-expansion-pack-configuration)

    -[BRCM Pcie Switch Expansion Pack Configuration](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/tree/main/README_Old.md?ref_type=heads#brcm-pcie-switch-expansion-pack-configuration)

#### Chapter 1 Prerequisite

See the [Yocto documentation](https://docs.yoctoproject.org/ref-manual/system-requirements.html#required-packages-for-the-build-host)
for the latest requirements

```sh
The OneTree Development environment, bash shell has to be the default shell.
    Give the following command to use bash as the default shell.
    $ sudo dpkg-reconfigure dash
    Select No in the appearing dialog and press Enter
```

```sh
Install python and pip 
    $ sudo apt-get install python 
    $ sudo apt-get install python-pip 
```

```sh
Install git python and yaml parser 
    $ sudo pip install gitpython 
    $ sudo pip install pyyaml 
```

##### Ubuntu
```
$ sudo apt install git python3-distutils gcc g++ make file wget \
    gawk diffstat bzip2 cpio chrpath zstd lz4 bzip2 git build-essential libsdl1.2-dev texinfo
```

##### Fedora
```
$ sudo dnf install git python3 gcc g++ gawk which bzip2 chrpath cpio
hostname file diffutils diffstat lz4 wget zstd rpcgen patch git build-essential libsdl1.2-dev texinfo
```

#### Chapter 2 CRB / EVB Build Instruction

##### Step 1) Common Repository for all the OneTree Build
```
- git clone https://git.ami.com/core/ami-bmc/base-tech/openbmc onetree; cd onetree
- git clone https://git.ami.com/core/ami-bmc/one-tree/core/meta-core
- git clone  https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami
```

##### Step 2) CRB/EVB Specific Repositories and Build Instruction

###### AST2600EVB
```
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs  
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```

###### AST2700EVB
```
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs (Only RedFish Extension Pack support)
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2700/meta-ast2700/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```

###### AST2700EVB DCSCM with Intel AvenCity CRB
```
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs (Only RedFish Extension Pack support)
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2700/meta-ast2700-pfr/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```

###### Intel EGS
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/egs meta-core/meta-egs
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-intel meta-core/meta-intel
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-core/meta-egs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```

###### Intel BHS
 ```
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/bhs meta-core/meta-bhs
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-intel meta-core/meta-intel
- add Intel Silicon Pack Features (BHS) 
    - git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted meta-core/meta-restricted
    - Add meta-restricted layer into “meta-core/META-XXX/conf/templates/default/bblayers.conf.sample” 

        BBLAYERS ?= " \
        :
        ##OEROOT##/meta-core/meta-bhs \
        ##OEROOT##/meta-core/meta-intel \
        ##OEROOT##/meta-core/meta-restricted \  <== Added
        :
    - Enable Packages for Intel Cups Services & Intel PMT Services
        Add EXTRA_IMAGE_FEATURES:append = " telemetry-features" in meta-core/META-XXX/conf/templates/default/local.conf.sample
    - Enable Packages for Intel Power Optimization Services
        Add EXTRA_IMAGE_FEATURES:append = " nm-features" in meta-core/META-XXX/conf/templates/default/local.conf.sample
    - Enable Packages for Intel RAS Services
        Add EXTRA_IMAGE_FEATURES:append = " ras-offload-features" in meta-core/META-XXX/conf/templates/default/local.conf.sample
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-core/meta-bhs/conf/templates/default . openbmc-env
- bitbake intel-platforms
```

###### NVIDIA MGX CG1(GH200)
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/nvidia/meta-nvidia meta-nvidia 
- git clone https://git.ami.com/core/ami-bmc/one-tree/nvidia/crb/mgx meta-nvidia/meta-mgx
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-nvidia/meta-mgx/conf/templates/legocg1 . openbmc-env 
- bitbake obmc-phosphor-image 
```

###### NVIDIA MGX C2 (Grace Superchip)
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/nvidia/meta-nvidia meta-nvidia 
- git clone https://git.ami.com/core/ami-bmc/one-tree/nvidia/crb/mgx meta-nvidia/meta-mgx
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-nvidia/meta-mgx/conf/templates/legoc2 . openbmc-env 
- bitbake obmc-phosphor-image 
```

###### AMD Chalupa
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/amd/chalupa meta-amd/meta-chalupa
- git clone https://git.ami.com/core/ami-bmc/one-tree/amd/amdpacks/apml meta-amd/meta-chalupa/recipes-amd/amd-apml 
- git clone https://git.ami.com/core/ami-bmc/one-tree/amd/amdpacks/addc meta-amd/meta-chalupa/recipes-amd/amd-addc 
- git clone https://git.ami.com/core/ami-bmc/one-tree/amd/amdpacks/power-capping meta-amd/meta-chalupa/recipes-amd/amd-power-capping 
- git clone https://git.ami.com/core/ami-bmc/one-tree/amd/amdpacks/amd-lcd-lib meta-amd/meta-chalupa/recipes-amd/amd-lcd-lib 
- git clone https://git.ami.com/core/ami-bmc/one-tree/amd/amd-common-next meta-amd/meta-common-next 
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-amd/meta-chalupa/conf/templates/default . openbmc-env 
- bitbake obmc-phosphor-image 
```

###### Ampere Mt. Mitchell
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ampere/mtmitchell.git; 
- git clone https://git.ami.com/core/ami-bmc/one-tree/ampere/common.git mtmitchell/meta-common
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=mtmitchell/conf/templates/default . openbmc-env 
- bitbake obmc-phosphor-image
```

###### Nuvoton Arbel
```
- Kindly refer to the "Chapter 3 Extension Pack Configuration" to add the Extension Packs
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-nuvoton/meta-evb-npcm845/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```


#### Chapter 3 Extension Pack Configuration

###### Redfish Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/redfish meta-ami/recipes-ami/redfish
- Enable Packages for Redfish

    When we download above URL , it will automatically starts building redfish expansion packs

    bmcweb append file itself will build redfish expansion packs. 
```

###### BRCM RAID Management Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/raid/raid-brcm meta-ami/recipes-ami/raid-brcm
- Enable Packages for BRCM RAID
    a.  Build for ast2600evb 
        a-1. Enable RAID and HBA features:
            Add IMAGE_INSTALL:append = " raid-mgmt hba-mgmt" in meta-core/META-XXX/conf/templates/default/local.conf.sample
        a-2. Set I2C OOB mode
            Kindly refer to "MegaRAC OneTree - BRCM RAID Management Expansion Pack Getting Started Guide", Chapter Config OOB (Out of Band) Interface 
    b.  Build for Other CRBs
        b-1. Enable RAID and HBA features:
            Add IMAGE_INSTALL:append = " raid-mgmt hba-mgmt" in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### MSCC RAID Management Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/raid/raid-mscc meta-ami/recipes-ami/raid-mscc
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/raid/storage meta-ami/recipes-ami/storage
- Enable Packages for MSCC RAID

    Add IMAGE_INSTALL:append = " raid-mscc storage-mgmt " in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### Intel ACD Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted meta-core/meta-restricted
- Add meta-restricted layer into “meta-core/META-XXX/conf/templates/default/bblayers.conf.sample” 

    BBLAYERS ?= " \
    :
    ##OEROOT##/meta-core/meta-bhs \
    ##OEROOT##/meta-core/meta-intel \
    ##OEROOT##/meta-core/meta-restricted \  <== Added
    :
- Enable Packages for Intel ACD

    Add IMAGE_INSTALL:append = " at-scale-debug" in meta-core/META-XXX/conf/templates/default/local.conf.sample
    Add IMAGE_INSTALL:append = " aic-crashdump crashdump ami-acd-dbus bafi-dev" in meta-core/META-XXX/conf/templates/default/local.conf.sample
    Add EXTRA_IMAGE_FEATURES:append = " acd-features" in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### Intel ASD Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted meta-core/meta-restricted
- Add meta-restricted layer into “meta-core/META-XXX/conf/templates/default/bblayers.conf.sample” 

    BBLAYERS ?= " \
    :
    ##OEROOT##/meta-core/meta-bhs \
    ##OEROOT##/meta-core/meta-intel \
    ##OEROOT##/meta-core/meta-restricted \  <== Added 
    :
- Enable Packages for Intel ASD

    Add IMAGE_INSTALL:append = " at-scale-debug ami-asd-dbus" in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### Intel MRT Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted meta-core/meta-restricted
- Add meta-restricted layer into “meta-core/META-XXX/conf/templates/default/bblayers.conf.sample” 

    BBLAYERS ?= " \
    :
    ##OEROOT##/meta-core/meta-bhs \
    ##OEROOT##/meta-core/meta-intel \
    ##OEROOT##/meta-core/meta-restricted \  <== Added
    :
- Enable Packages for Intel MRT

    Add those configurations as below in ./meta-core/meta-restricted/conf/layer.conf 

    Add IMAGE_INSTALL:append = " memory-resilience-technology-engine memory-error-collector" in meta-core/META-XXX/conf/templates/default/local.conf.sample

- Enable Redfish Expansion Pack
```

###### Intel PFR Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/intel/meta-restricted meta-core/meta-restricted
- Add meta-restricted layer into “meta-core/META-XXX/conf/templates/default/bblayers.conf.sample” 

    BBLAYERS ?= " \
    :
    ##OEROOT##/meta-core/meta-bhs \
    ##OEROOT##/meta-core/meta-intel \
    ##OEROOT##/meta-core/meta-restricted \  <== Added
    :
- Enable Packages for Intel PFR

    Step 1 Enable PFR 
        Enable Intel PFR Support 
            Add IMAGE_FSTYPES += "intel-pfr" in meta-core/META-XXX/conf/templates/default/local.conf.sample
    
    Step 2 BHS Only, Enable 128MB vs 256MB BMC SPI Support 
        For 256MB BMC SPI support: 
            Add PFR_CONFIG = “pfr-256” in meta-core/META-XXX/conf/templates/default/local.conf.sample
        For 128MB BMC SPI support:
            Add PFR_CONFIG = “pfr-128” in meta-core/META-XXX/conf/templates/default/local.conf.sample

    For additional details (flashing, provisioning, usage), please refer to user’s guide. (MegaRAC OneTree™ - PFR Expansion Pack UserGuide )
```

###### GPGPU Management Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/gp-gpu/nvidia-gpgpu meta-ami/recipes-gpgpu 
- Enable Packages for GPGPU

    Add recipes libmctp, pciutils, nvidia-gpuoob & nvidia-gpumgr in variable IMAGE_INSTALL under 
build/conf/local.conf 
```

###### Firmware Update Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/firmware-update.git meta-ami/meta-common/recipes-fwupdate
- Enable Packages for NON PFR Firmware Update
    a.  Enable CPLD Non PFR Update 
        OneTree™ provides mechanism to support CPLD firmware upgrade via jtag/spi/i2c interface. This feature will populate the CPLD Inventory and provide user mechanism to update the cpld using redfish update service. 

        Step 1: Comment out intel-pfr from IMAGE_FSTYPES in meta-core/META-XXX/conf/templates/default/local.conf.sample:
            # PFR image Build 
            #IMAGE_FSTYPES += "intel-pfr"

        Step 2: Enable CPLD
            Add NON_PFR_UPDATE_FEATURES:append = " cpld-update" in meta-core/META-XXX/conf/templates/default/local.conf.sample

    b.  Enable Signing Support 
        OneTree™ provides feature and mechanism that can be utilized to implement secure firmware updates and image verification. Before deploying firmware or software updates, you can sign the images using a cryptographic algorithm like RSA or ECC. This ensures that the images can be verified for authenticity and integrity during the update process. 

        Add NON_PFR_UPDATE_FEATURES:append = " image-sign" in meta-core/META-XXX/conf/templates/default/local.conf.sample

    c.  Enable Dual Image Support  
        OneTree™ allows you to maintain two separate firmware images, commonly referred to as the primary and secondary images. One of these images is designated as the active image, while the other serves as a backup. OneTree™ can install the updated firmware into the bkup image slot while the active image remains untouched.

        Add NON_PFR_UPDATE_FEATURES:append = " dual-image" in meta-core/META-XXX/conf/templates/default/local.conf.sample

        Enable Hardware fails safe, single spi abr support, sync conf 

        Add NON_PFR_DUAL_FEATURES= " hw-failsafe-boot" in meta-core/META-XXX/conf/templates/default/local.conf.sample
        Add NON_PFR_DUAL_FEATURES= " single-spi-abr" in meta-core/META-XXX/conf/templates/default/local.conf.sample
        Add NON_PFR_DUAL_FEATURES= " sync-conf" in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### AMD Remote Debug Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/amd/amdpacks/remote-debug meta-amd/meta-chalupa/recipes-amd/amd-remote-debug
- Enable Packages for AMD Remote Debug

    Add IMAGE_INSTALL:append += “ amd-remote-debug” in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### NIC Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/nic meta-ami/recipes-ami/nic
- Enable Packages for NIC

    Add IMAGE_INSTALL:append = " nic-mgmt" in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### NVMe Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/nvme meta-ami/recipes-ami/nvme 
- Enable Packages for NVMe. Only one of onetree-nvme and onetree-nvmebasic can be enabled at a time

    a. Enable NVMe Management 
        Add IMAGE_INSTALL:append = " nvme nvme-mgmt" in meta-core/META-XXX/conf/templates/default/local.conf.sample
    b. Enable NVMe Basic Management 
        Add IMAGE_INSTALL:append = " nvme-basic nvmebasic-mgmt" in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

###### BRCM Pcie Switch Expansion Pack Configuration
```
- git clone https://git.ami.com/core/ami-bmc/one-tree/ami/amipacks/pciesw-brcm.git meta-ami/recipes-ami/pciesw-brcm
- Enable Packages for PCIe Switch
    a. Enable Pcie Switch I2C Pciesw 
        Add IMAGE_INSTALL:append = " i2c-pciesw " in meta-core/META-XXX/conf/templates/default/local.conf.sample
    b. Enable Pcie Switch Libscrutiny 
        Add IMAGE_INSTALL:append = " libscrutiny " in meta-core/META-XXX/conf/templates/default/local.conf.sample
    c. Enable Pcie Switch BRCM MCTP 
        Add IMAGE_INSTALL:append = " mctp-pciesw " in meta-core/META-XXX/conf/templates/default/local.conf.sample
    d. Enable Pcie Switch Pciesw Service Interface 
        Add IMAGE_INSTALL:append = " pciesw-service " in meta-core/META-XXX/conf/templates/default/local.conf.sample
    e. Enable Pcie Switch Scrutiny Service Interface 
        Add IMAGE_INSTALL:append = " scrutiny-ifc " in meta-core/META-XXX/conf/templates/default/local.conf.sample
```

### Notes
- Package groups will be used for features and expansion pack configuration, also build script will be given to simplify the build process from OneTree2.1
- By default root user is disabled in the stack except AST2600EVB
- uncomment EXTRA_IMAGE_FEATURES += "debug-tweaks" in build/conf/local.conf to enable the root user access

