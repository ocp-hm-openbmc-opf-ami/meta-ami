# Enable downstream autobump - this can be removed after upstream sync
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/obmc-console;branch=master;protocol=https"
SRCREV = "3453084b579970cd368357bf091f173924ecba5e"

FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"
OBMC_CONSOLE_HOST_TTY = "ttyS2"
SRC_URI += "file://sol-configure.sh \
            file://pre-post-routing.conf \
            file://server.ttyS2.conf \
            file://0001-Use-sol-configure.sh-to-configure-UART-routing.patch \
           "

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/sol-configure.sh ${D}${bindir}

    local drop_in=${D}${sysconfdir}/systemd/system/${PN}@${OBMC_CONSOLE_HOST_TTY}
    local service_drop_in=${drop_in}.service.d

    # Install service drop-in override to add UART routing and baud configuration
    install -d $service_drop_in
    install -m 0644 ${WORKDIR}/pre-post-routing.conf $service_drop_in
}
