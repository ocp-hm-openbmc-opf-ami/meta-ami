# Define an empty IMAGE_CMD for 'intel-pfr' to prevent BitBake parsing errors.
# Note: We are not building the 'intel-pfr' image type for ast2700-dcsm,
# but we use 'intel-pfr' as an identifier to enable PFR-related features in other modules.
# This no-op command ensures that if BitBake checks for IMAGE_CMD_intel-pfr, it will not fail.
#`IMAGE_CMD:intel-pfr = "true"
