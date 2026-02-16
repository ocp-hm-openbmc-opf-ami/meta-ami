FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI:append = " \
    file://gpioCallbackHandler.cpp \
    file://gpioCallbackHandler.hpp \
    "

SRC_URI:append = "${@bb.utils.contains('MACHINE', 'evb-npcm845','','file://0001-Add-CallbackHandler-support-for-GpioMonitor.patch', d)}"

SRC_URI:append:evb-npcm845 = " file://0001-Add-CallbackHandler-support-for-arbel-GpioMonitor.patch "

do_unpack:append(){
    bb.build.exec_func('copy_impl_files', d)
}

copy_impl_files() {
    cp ${WORKDIR}/gpioCallbackHandler.cpp ${S}/
    cp ${WORKDIR}/gpioCallbackHandler.hpp ${S}/
}
