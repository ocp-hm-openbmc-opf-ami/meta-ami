FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

#DEPENDS += "cyrus-sasl"

PACKAGECONFIG[ldap] = "--enable-ldap"
#PACKAGECONFIG[sasl] = "--with-cyrus-sasl"
PACKAGECONFIG[spasswd] = "--enable-spasswd"

