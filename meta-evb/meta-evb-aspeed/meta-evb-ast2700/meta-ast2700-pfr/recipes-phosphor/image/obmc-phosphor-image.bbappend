# AST2700 A0 doesn't support port80 direct to SGPIOS.
# We added a set-post-code-led to transfer BIOS post code values to SGPIOS[16:23].
IMAGE_INSTALL:append = " set-post-code-led"

# AST2700 A0 doesn't support SGPIO Slave interrupt.
# If the SGPIOS input pin is configured for x86-power-control PowerOk,
# the power status will not update.
# We use phosphor-inventory-manager to create DBus,
# and use power-status-sync.sh to poll SGPIOS status to update DBus.
IMAGE_INSTALL:append = " power-status-sync"
