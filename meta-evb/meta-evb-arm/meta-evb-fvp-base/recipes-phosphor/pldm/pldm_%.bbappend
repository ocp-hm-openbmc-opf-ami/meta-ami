FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRCREV = "ef16cdecca9ed5186f44577b57fa190ab959da56"
PACKAGECONFIG[oem-ampere] = "-Doem-ampere=enabled, -Doem-ampere=disabled, libcper"
PACKAGECONFIG[fw-update-pkg-inotify] = ""
PACKAGECONFIG[oem-meta] = ""

EXTRA_OEMESON:append = " \
  -Dresponse-time-out=4800 \
  -Ddbus-timeout-value=10 \
"

SRC_URI:append = " \
  file://host_eid \
  file://0001-Fix-stdexec-inline_scheduler-namespace-for-newer-exe.patch \
"

# GCC 15 marks std::wstring_convert as deprecated and this project uses -Werror.
CXXFLAGS:append = " -Wno-error=deprecated-declarations"

do_install:append() {
    install -d ${D}/usr/share/pldm/bios
    install -D -m 0644 ${UNPACKDIR}/host_eid ${D}/usr/share/pldm
}
