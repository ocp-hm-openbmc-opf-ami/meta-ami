SRC_URI:remove = "${SRC_URI_TRUSTED_FIRMWARE_A};name=tfa;branch=${SRCBRANCH}"
SRC_URI:append = "git://github.com/Nuvoton-Israel/arm-trusted-firmware.git;protocol=https;name=tfa;branch=npcm_2_9"
SRCREV_tfa = "5e4ca315934016d02b59a10199dc769bde8c6ef7"

