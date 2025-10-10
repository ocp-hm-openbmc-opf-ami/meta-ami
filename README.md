# firmware.bmc.openbmc.yocto.meta-core
This repo contains the meta-core layer that is used to build Intel`s
OpenBMC firmware supporting Intel's reference platforms.

This repo will be updated based on Intel Best-Known Configuration (BKC)
releases. Each release will be provided as a single squashed commit. The
compatible version of the [Linux Foundation (LF) OpenBMC repo][1] will be
included in each commit message.

## Important Information
- After Stable release features migrated into the main branch, the tag "OneTree-X.X" is created in the main repositories. The tag is just providing the information "when the milestone New feature/feature enhancement migration Finished" Only. The latest main branch always provides the latest Bug fixed and Feature enhancement. **Please take the latest main Branch for the project development.**

## How to build Intel-BMC
1. `git clone` the [LF OpenBMC repo][1] into a folder named `openbmc-openbmc`
2. `git clone` this repo into a folder named
`openbmc-openbmc/meta-core`
3. In `openbmc-openbmc/meta-core`, `git checkout` the BKC version to
build and check the commit message for the compatible LF OpenBMC version
4. In `openbmc-openbmc`, `git checkout` the compatible LF OpenBMC version
5. Set TEMPLATECONF to the layer for the desired platform. For example, to
build meta-bhs use:
```sh
export TEMPLATECONF=meta-core/meta-bhs/conf/templates/default
```
6. Source the init script
```sh
source oe-init-build-env
```
7. Edit the `openbmc-openbmc/build/conf/local.conf` file as desired, see
[these-instructions](#How-to-prepare-localconf) for examples
8. If building a signed image, see [these instructions](#how-to-prepare-keys)
to prepare keys
9. Build with
```sh
bitbake intel-platforms
```

When completed, the binaries will be available under
`openbmc-openbmc/build/tmp/deploy/images/<machine>/pfr_images`. The full SPI
ROM image will be under a symlink named `image-mtd-pfr.bin`, and the Redfish
update image will be under a symlink named `bmc_signed_cap.bin`

If enabled, there will also be D-segment equivalent images present.

## How to prepare local.conf
The local.conf file contains various options to configure the build. Here are
some common configuration changes that may be desired:

* Enable `debug-tweaks` for debug features and default credentials
* Comment out `optee` feature lines if the source is inaccessible
* Remove any inaccessible `advanced features` from the
`EXTRA_IMAGE_FEATURES:append` list

## How to prepare keys
When building Intel-BMC, the common configurations will require keys to sign
the image. The keys are not included with the source, so they must be made
available locally during the build.

### Adding keys for Intel Platform Firmware Resiliency (PFR) builds
A common configuration of Intel-BMC is a PFR-enabled build. This build requires
two key-pairs and a certificate. In platforms where PFR is provisioned, these
keys must match the platform keys.

Otherwise, local keys can be generated to complete the build as follows:

- From the latest source, this script can be executed to generate local keys
for the build:

  `scripts/gen-bmc-sign-keys.py`

- If not at the latest, the build may be configured to automatically generate
and include local keys.

- If the build doesn't support this, local keys can be manually included as
follows:

  Generate local keys using these commands:
  ```sh
  mkdir -p openbmc-openbmc/meta-core/keys
  cd openbmc-openbmc/meta-core
  openssl ecparam -out keys/csk_prv.pem -name secp384r1 -genkey
  openssl ec -in keys/csk_prv.pem -pubout -out keys/csk_pub.pem
  openssl ecparam -out keys/rk_prv.pem -name secp384r1 -genkey
  openssl ec -in keys/rk_prv.pem -pubout -out keys/rk_pub.pem
  openssl req -new -key keys/rk_prv.pem -x509 -nodes -days 365 -out keys/rk_cert.pem
  ```

  Include these local keys in the build by providing the path to the key file
  in the call to `external-signing-utility`. These calls are found in the
  following files in the meta-layer you are building:

  * recipes-intel/intel-pfr/obmc-intel-pfr-image-native.bbappend
  * recipes-intel/intel-pfr/obmc-intel-pfr-image-native/bmc_config.xml
  * recipes-intel/intel-pfr/obmc-intel-pfr-image-native/pfm_config.xml

  If enabled, you will also need to set the local keys for D-segment:

  * recipes-intel/intel-pfr/obmc-intel-pfr-image-native/bmc_config_d.xml
  * recipes-intel/intel-pfr/obmc-intel-pfr-image-native/pfm_config_d.xml


[1]: https://github.com/openbmc/openbmc
