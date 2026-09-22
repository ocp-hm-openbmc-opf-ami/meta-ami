NXP i.MX9x OpenBMC BSP Layer (`meta-nxp`)
=========
This is the NXP i.MX9x Board Support Package (BSP) Yocto layer for enabling
OpenBMC on NXP i.MX 9X series SoCs, including i.MX91, i.MX93, i.MX943 & i.MX95.
These SoCs are ARM-based platforms with external DDR and support
a large set of peripherals of NXP.

More information about the NXP IMX 9 Application Processors can be found at:
[here](https://www.nxp.com/products/processors-and-microcontrollers/arm-processors/i-mx-applications-processors/i-mx-9-processors:IMX9-PROCESSORS).

---

## 1. Layer Dependencies

This layer is applicable for OpenBMC github project: 

- `https://github.com/openbmc/openbmc`

This layer depends on the following OpenBMC/Yocto layers:

- `meta`
- `meta-phosphor`
- `meta-openembedded` (meta-oe, meta-networking, meta-python)
- `meta-security`


This repository also includes NXP-specific sublayers:

- `meta-common` (shared BSP content such as meta-imx-bsp)
- `meta-imx91`
- `meta-imx93`
- `meta-imx943`
- `meta-imx95`

---

## 2. NXP Kernel / Dependent Trees

The BSP integrates the NXP Linux kernel:

```
- NXP Kernel Tree :
  URI: https://github.com/nxp-imx/linux-imx
  branch: lf-6.12.y
  tag: lf-6.12.49-2.2.0
```

Additional dependent components included:

```
- NXP U-Boot:
  URI: https://github.com/nxp-imx/uboot-imx
  branch: lf_v2025.04
  tag: lf-6.12.49-2.2.0

- NXP ARM Trusted Firmware / ATF:
  URI: https://github.com/nxp-imx/uboot-imx
  branch: lf_v2.12
  tag: lf-6.12.49-2.2.0

- NXP System Manager / SM:
  URI: https://github.com/nxp-imx/imx-sm
  branch: master
  tag: lf-6.12.49-2.2.0

- NXP OEI:
  URI: https://github.com/nxp-imx/imx-oei
  branch: master
  tag: lf-6.12.49-2.2.0

- NXP mkimage:
  URI: https://github.com/nxp-imx/imx-mkimage
  branch: lf-6.12.49-2.2.0
  tag: lf-6.12.49-2.2.0

- Optional secure boot and platform-specific firmware overlays

This layer also depends on:

URI: git://git.openembedded.org/openembedded-core
layers: meta
branch: master
revision: HEAD

URI: https://github.com/openbmc/meta-phosphor
branch: master
revision: HEAD
```

---

## 3. Supported Machines

This layer currently supports:

- `evb-imx91`
- `evb-imx93`
- `evb-imx943`
- `evb-imx95`

Each SoC family has its own sublayer with machine definition under:

```
meta-nxp/meta-imx91/conf/machine
meta-nxp/meta-imx93/conf/machine
meta-nxp/meta-imx943/conf/machine
meta-nxp/meta-imx95/conf/machine
```

---

## 4. Basic Build Instructions

Get the Yocto Source Code:
```bash
git clone https://github.com/openbmc/openbmc.git
cd openbmc
git checkout -b walnascar origin/walnascar
git clone https://github.com/nxp-imx-support/meta-nxp-openbmc.git meta-nxp

```


Set-up build environment for selected machine:
```bash
. setup evb-imx93
# or evb-imx91 / evb-imx943 / evb-imx95
```

Build the image:
```bash
bitbake obmc-phosphor-image
```

If any package fails, you can build that package separately by using below command:
```bash
bitbake -c clean <Package_NAME>; bitbake <Package_NAME>
```

Note: "wic" image will be available at "tmp/deploy/images/<board_name>" path.

## 5. Directory Structure

```
meta-common        Shared BSP code (kernel notes, meta-imx-bsp, licenses)
meta-imx91         SoC-specific machine + recipes
meta-imx93         SoC-specific machine + recipes
meta-imx943        SoC-specific machine + recipes
meta-imx95         SoC-specific machine + recipes

recipes-bsp        Bootloader, ATF, skiboot, low-level BSP
recipes-core       Core OS modifications (udev, etc.)
recipes-example    Example recipes
recipes-kernel     Kernel recipes and config
recipes-phosphor   Platform-level phosphor services (gpio, host, images, etc.)
recipes-support    Misc supporting libraries
scripts            Helper scripts (console, state, service control)
wic                WIC image layout per SoC
```

For detailed per-directory modifications, see `recipes.txt`.

---
