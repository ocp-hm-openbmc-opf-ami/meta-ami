# Disable unused AMI sensor daemons for tiogapass.
PACKAGECONFIG:remove = " \
    acpidevicestatus \
    acpisystemstatus \
    batterystatus \
    osstatus \
    processorstatus \
    powerunitstatus \
    logstatus \
    apisensor \
    damagedsensor \
"
