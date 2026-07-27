# Enable LDAP so the recipe gets its required build deps.
DEPENDS += "openldap"
PACKAGECONFIG:append = " ldap"
