FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"
SRCREV = "10612f3fe552ea8141ed1960a6c2df088cff0b92"

SRC_URI:append = " \
    file://AVC-2DPC-Baseboard.json \
    file://AC-Baseboard.json \
    file://solum_pssf162202_psu.json \
    file://AVC-Baseboard.json \
    "
