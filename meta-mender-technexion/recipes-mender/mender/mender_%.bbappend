FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://server.crt"
SRC_URI_append_mender-signing = " file://artifact-verify-key.pem"
MENDER_SERVER_URL = "https://ota.technexion.net"
# build mender update modules (plugins)
PACKAGECONFIG_append = " modules"
