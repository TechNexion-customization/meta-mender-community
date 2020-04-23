FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://server.crt"
MENDER_SERVER_URL = "https://mender.technexion.net"
# build mender update modules (plugins)
PACKAGECONFIG_append = " modules"
