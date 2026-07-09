# MegaRAC OneTree
- MegaRAC OneTree is AMI’s next generation BMC firmware solution following MegaRAC SP-X 13.
- Based on OpenBMC from linux foundation. All the SDK from SoC and Si vendors are integrated into OneTree as single stack to support multi SoC and multi silicon.
- Built on pervasive, open-source industry tools, architecture, and standards such as Yocto, BitBake, OpenEmbedded, D-bus etc.. 
- Enriched with added core feature sets for platform manageability
- Enhanced by AMI advanced technologies such as Expansion Packs (EP) and Silicon Packs (SiP)
- Backed by AMI’s premium customer support

### Important Information
- After Stable release features migrated into the main branch, the tag "OneTree-X.X" is created in the main repositories. The tag is just providing the information "when the milestone New feature/feature enhancement migration Finished" Only. The latest main branch always provides the latest Bug fixed and Feature enhancement. **Please take the latest main Branch for the project development.**

### Download & Build Code Instruction 

    Please take Note: 

        1. You have to download and build the source with non-root user. 
        2. Final image will be available in build/tmp/deploy/images/<platform-name>/ 
            Example: build/tmp/deploy/images/intel-ast2600/image-mtd 
        3. In the Build instruction, kindly use correct symbol instead of "META-XXX". you can access BuildWorkspace/meta-core to get more information. 
            Example: In BHS project, META-XXX should be replaced by "meta-bhs"

#### Agenda

* [Latest Download & Build Instructions](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_New.md)

* [Before OneTree Package Groups configuration started 2025/04/16 Download & Build Instructions](https://git.ami.com/core/ami-bmc/one-tree/core/meta-ami/-/blob/main/README_Old.md)

### Notes
- Package groups will be used for features and expansion pack configuration, also build script will be given to simplify the build process from OneTree2.1
- By default root user is disabled in the stack except AST2600EVB
- uncomment EXTRA_IMAGE_FEATURES += "debug-tweaks" in build/conf/local.conf to enable the root user access

