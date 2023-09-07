FILESEXTRAPATHS:prepend := "${@'${THISDIR}/${PN}:' if '${MULTI_SOL_ENABLED}' == '1' else ''}"
RDEPENDS:${PN} += "bash"

# Declare port specific config files
OBMC_CONSOLE_TTYS = "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', "ttyS0 ttyS1 ttyS2 ttyS3", OBMC_CONSOLE_HOST_TTY ,  d)}"
CONSOLE_CLIENT = "2200 2201 2202 2203"

CONSOLE_SERVER_CONF_FMT = "file://server.{0}.conf"
CONSOLE_CLIENT_CONF_FMT = "file://client.{0}.conf"
CONSOLE_CLIENT_SERVICE_FMT = "obmc-console-ssh@{0}.service"

MULTI_SOL_SRC_URI = " \
		${@compose_list(d, 'CONSOLE_SERVER_CONF_FMT', 'OBMC_CONSOLE_TTYS')} \
    		${@compose_list(d, 'CONSOLE_CLIENT_CONF_FMT', 'CONSOLE_CLIENT')} \
	"

SOL_SYSTEMD_SERVICE = " \
        ${PN}@${OBMC_CONSOLE_HOST_TTY}.socket \
        "
MULTI_SOL_SYSTEMD_SERVICE = " \
        ${@compose_list(d, 'CONSOLE_CLIENT_SERVICE_FMT', 'CONSOLE_CLIENT')} \
        "

SRC_URI += "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', MULTI_SOL_SRC_URI, ' ', d)}"

SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', "obmc-console-ssh.socket", ' ',  d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', SOL_SYSTEMD_SERVICE, ' ', d)}"

SYSTEMD_SERVICE:${PN}:append = "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', MULTI_SOL_SYSTEMD_SERVICE, ' ', d)}"

FILES:${PN}:remove = "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', '${systemd_system_unitdir}/obmc-console-ssh@.service.d/use-socket.conf', ' ', d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', " concurrent-servers", ' ', d)}"

do_install:append() {
if [ "${MULTI_SOL_ENABLED}" = "1" ]; then
    #Removing files appended from openbmc-meta-intel recipe.
    rm -rf ${D}${bindir}/sol-configure.sh

    local drop_in=${D}${sysconfdir}/systemd/system/${PN}@${OBMC_CONSOLE_HOST_TTY}
    local service_drop_in=${drop_in}.service.d
    local socket_drop_in=${drop_in}.socket.d

    rm -rf $socket_drop_in
    rm -rf $service_drop_in

    #Rules to automatically start services for multiple TTY
    install -d ${D}${base_libdir}/udev/rules.d
    install -m 0644 ${S}/conf/80-obmc-console-uart.rules.in ${D}${base_libdir}/udev/rules.d/80-obmc-console-uart.rules
    
    #Install the console client configurations
    install -m 0644 ${WORKDIR}/client.*.conf ${D}${sysconfdir}/${BPN}/

fi
}
