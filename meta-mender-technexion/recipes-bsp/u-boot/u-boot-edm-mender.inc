FILESEXTRAPATHS_prepend := "${THISDIR}/u-boot-edm/:${THISDIR}/u-boot-edm/${MACHINE}:"

# Apply overlay patch to env_mender.h
SRC_URI_append = " file://0009-env_mender-header-patch-for-fdtoverlay.patch"

# Apply the config patch first to add to defconfig
SRC_URI_append = " file://0010-Improve-boot-startup-time.patch"

# Integration of mender in the header file
SRC_URI_append = " file://0011-${MACHINE}-header-file-mender-integration.patch"

MENDER_UBOOT_AUTO_CONFIGURE = "1"
BOOTENV_SIZE = "0x2000"
