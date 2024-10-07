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
### 2) Common Repository for All the Build
```
- git clone https://github.com/ocp-hm-openbmc-opf-ami/openbmc openbmc; cd openbmc
- git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-common
- git clone https://github.com/ocp-hm-openbmc-opf-ami/meta-ami
```
### 3) AST2600EVB Build Instruction
```
- meta-ami/github-gitlab-url.sh
- Add the other meta layer and features (optional)
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2600/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```
### 4) Nuvoton Arbel Build Instruction
```
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-nuvoton/meta-evb-npcm845/conf/templates/default . openbmc-env 
- bitbake obmc-phosphor-image
```

### 5) AST2700EVB Build Instruction
```
- meta-ami/github-gitlab-url.sh
- TEMPLATECONF=meta-ami/meta-evb/meta-evb-aspeed/meta-evb-ast2700/meta-ast2700/conf/templates/default . openbmc-env
- bitbake obmc-phosphor-image
```
### Notes
- By default root user is disabled in the stack except AST2600EVB
- uncomment EXTRA_IMAGE_FEATURES += "debug-tweaks" in build/conf/local.conf to enable the root user access

