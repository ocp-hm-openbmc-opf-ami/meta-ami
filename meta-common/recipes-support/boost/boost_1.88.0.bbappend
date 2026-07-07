# Add boost-random package that was missing
PACKAGES =+ "${PN}-random"
FILES:${PN}-random = "${libdir}/libboost_random.so.*"
