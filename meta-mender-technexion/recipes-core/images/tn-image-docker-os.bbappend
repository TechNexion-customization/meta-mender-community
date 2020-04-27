IMAGE_FEATURES_append = " package-management "

IMAGE_INSTALL += " \
    packagegroup-mender-update-modules \
"

DEPENDS += "docker-disk"
