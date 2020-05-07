SUMMARY = "Wrap a firmware.bin into a .mender artifact for mender-dfu update module plugin"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# ------------------------------ CONFIGURATION ---------------------------------

# Extra arguments that should be passed to mender-artifact.
MENDER_ARTIFACT_EXTRA_ARGS ?= ""

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

# The firmware file to install to target device
MENDER_ARTIFACT_FIRMWARE_FILE ?= ""

# --------------------------- CONCEPT EXPLANATION -----------------------------
#
# Use the dfu-artifact-gen from mender-dfu-native to create the .mender artifact
#
# NOTE: dfu-artifact-gen calls mender-artifact x86_64 binary (from mender-artifact-native)
# to generate the final .mender artifact.
#
# ARTIFACT_NAME="my-update-1.0"
# DEVICE_TYPE="my-device-type"
# ./dfu-artifact-gen --artifact-name ${ARTIFACT_NAME} \
#                    --device-type ${DEVICE_TYPE} \
#                    --firmware-file firmware.bin
# ARTIFACT_NAME - The name of the Mender Artifact
# DEVICE_TYPE - The compatible device type of this Mender Artifact
#

inherit deploy

DEPENDS += "mender-dfu-native mender-artifact-native"

S = "${WORKDIR}"
B = "${S}/build"

BUILD_NUMBER="${@ '0' if d.getVar('MENDER_ARTIFACT_NAME', True) is None else '%s' % d.getVar('MENDER_ARTIFACT_NAME', True).split('-')[-1] }"
ARTIFACT_NAME = "${PN}-${BUILD_NUMBER}"
OUTPUT_PATH="${ARTIFACT_NAME}.mender"

# ensure do_install depends on native binaries build in hosttools
do_deploy[depends] = "mender-dfu-native:do_populate_sysroot mender-artifact-native:do_populate_sysroot"

do_deploy () {
	bbnote "Generate mender-dfu-artifact: ${OUTPUT_PATH}"

	# generate the mender firmware-file artifact
	dfu-artifact-gen -n ${ARTIFACT_NAME} -t ${MACHINE} -f ${MENDER_ARTIFACT_FIRMWARE_FILE} -- ${MENDER_ARTIFACT_EXTRA_ARGS}
	if [ -f "${MENDER_ARTIFACT_SIGNING_KEY}" ]; then
		mender-artifact sign ${OUTPUT_PATH} -k ${MENDER_ARTIFACT_SIGNING_KEY} -o ${ARTIFACT_NAME}.signed.mender
		install -m 644 ${B}/${ARTIFACT_NAME}.signed.mender ${DEPLOYDIR}/${ARTIFACT_NAME}.signed.mender
	fi
	install -m 644 ${B}/${OUTPUT_PATH} ${DEPLOYDIR}/${OUTPUT_PATH}
}

addtask deploy after do_packagedata do_package

PACKAGES = "${PN}"
