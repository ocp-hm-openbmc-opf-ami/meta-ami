FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/sdbusplus;branch=master;protocol=https"
#SRCREV = "4059635ff098987ffa04ec30017c9f1d7c83fd1b"
#SRCREV = "2a12ae12455bfa1cdf92dff21c16757b1f126c8f"

SRC_URI += " \
             file://0001-fix-cpp20-move-only-function.patch \
             file://0002-Skip-decoding-some-dbus-identifiers.patch \
             file://0003-asio-connection-Expose-dbus-message-to-handler-on-error.patch \
           "

DEPENDS += " \
        nlohmann-json \
           "

# GCC 14+ warns on built-in type traits used in function signatures in
# bundled stdexec headers. Treating warnings as errors breaks the build.
# Allow warnings for this recipe to keep the toolchain upgrade unblocked.
CXXFLAGS:append = " -Wno-error"
CPPFLAGS:append = " -Wno-error"
