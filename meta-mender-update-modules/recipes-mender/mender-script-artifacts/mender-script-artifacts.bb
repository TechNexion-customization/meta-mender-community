SUMMARY = "Wrap shell scripts into a .mender artifact for mender-script update module plugin"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# ------------------------------ CONFIGURATION ---------------------------------

# The private key file used to sign the mender update.
# e.g. RSA
# openssl genpkey -algorithm RSA -out private.key -pkeyopt rsa_keygen_bits:3072
# openssl rsa -in private.key -out private.key
# openssl rsa -in private.key -pubout -out public.key
# e.g. ECDSA256
# openssl ecparam -genkey -name prime256v1 -out private-and-params.key
# openssl ec -in private-and-params.key -out private.key
# openssl ec -in private-and-params.key -pubout -out public.key
MENDER_ARTIFACT_SIGNING_KEY ?= ""

# The path to the script that you wish to "deploy" and "execute" on your device.
# NOTE that the extension does not matter.
MENDER_ARTIFACT_SHELL_SCRIPTS ?= ""

# --------------------------- CONCEPT EXPLANATION -----------------------------
#
# Use mender-artifactn from mender-artifact-native to create the .mender artifact
#
# ARTIFACT_NAME="my-update-1.0"
# DEVICE_TYPE="my-device-type"
# OUTPUT_PATH="my-update-1.0.mender"
# SHELL_SCRIPTS="my-script-1.sh my-script-2.sh"
# mender-artifact write module-image -T script -n ${ARTIFACT_NAME} -t ${DEVICE_TYPE} -o ${OUTPUT_PATH} -f $(echo "$SHELL_SCRIPTS" | sed -e 's/ / -f /g')
#

inherit deploy

DEPENDS += "mender-artifact-native"

S = "${WORKDIR}"
B = "${S}/build"

BUILD_NUMBER="${@ '0' if d.getVar('MENDER_ARTIFACT_NAME', True) is None else '%s' % d.getVar('MENDER_ARTIFACT_NAME', True).split('-')[-1] }"
ARTIFACT_NAME = "${PN}-${BUILD_NUMBER}"
OUTPUT_PATH="${ARTIFACT_NAME}.mender"

# ensure do_install depends on native binaries build in hosttools
do_deploy[depends] = "mender-artifact-native:do_populate_sysroot"

do_deploy () {
	bbnote "Generate mender-script-artifact: ${OUTPUT_PATH}"

	# generate the mender script artifact
    mender-artifact write module-image -T script -n ${ARTIFACT_NAME} -t ${MACHINE} -o ${OUTPUT_PATH} -f $(echo "${MENDER_ARTIFACT_SHELL_SCRIPTS}" | sed -e 's/ / -f /g')
	if [ -f "${MENDER_ARTIFACT_SIGNING_KEY}" ]; then
		mender-artifact sign ${OUTPUT_PATH} -k ${MENDER_ARTIFACT_SIGNING_KEY} -o ${ARTIFACT_NAME}.signed.mender
		install -m 644 ${B}/${ARTIFACT_NAME}.signed.mender ${DEPLOYDIR}/${ARTIFACT_NAME}.signed.mender
	fi
	install -m 644 ${B}/${OUTPUT_PATH} ${DEPLOYDIR}/${OUTPUT_PATH}
}

addtask deploy after do_packagedata do_package

PACKAGES = "${PN}"
