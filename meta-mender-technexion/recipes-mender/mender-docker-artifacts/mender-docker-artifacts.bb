# Generates docker containers artifacts which allows mender-docker update module
# plugin to update docker containers on target device.
# i.e. generate a .mender artifact.

SUMMARY = "Wrap dockerhub container-name:tags into a .mender artifact for mender-docker update module plugin"
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

# The list of container-names:tags (from dockerhub) to be wrapped into .mender packages
MENDER_ARTIFACT_DOCKERHUB_IMAGES ?= "technexion/debian-buster-wayland:latest"

# --------------------------- CONCEPT EXPLANATION -----------------------------
#
# Use the docker-artifact-gen from mender-docker-native to create the .mender artifact
#
# NOTE: docker-artifact-gen calls mender-artifact x86_64 binary (from mender-artifact-native)
# to generate the final .mender artifact.
#
# ARTIFACT_NAME="my-container-update-1.0"
# DEVICE_TYPE="my-device-type"
# OUTPUT_PATH=my-container-update-1.0.mender
# DOCKER_IMAGES="docker-image-1 docker-image2"
# ./docker-artifact-gen -n ${ARTIFACT_NAME} -t ${DEVICE_TYPE} -o ${OUTPUT_PATH} ${DOCKER_IMAGES} -- ${MENDER_ARTIFACT_EXTRA_ARGS}
#

inherit deploy

DEPENDS += "jq-native mender-docker-native mender-artifact-native"

S = "${WORKDIR}"
B = "${S}/build"

BUILD_NUMBER="${@ '0' if d.getVar('MENDER_ARTIFACT_NAME', True) is None else '%s' % d.getVar('MENDER_ARTIFACT_NAME', True).split('-')[-1] }"
ARTIFACT_NAME = "${PN}-${BUILD_NUMBER}"
OUTPUT_PATH="${ARTIFACT_NAME}.mender"

# ensure do_install depends on native binaries build in hosttools
do_deploy[depends] = "jq-native:do_populate_sysroot mender-docker-native:do_populate_sysroot mender-artifact-native:do_populate_sysroot"

do_deploy () {
	bbnote "Generate mender-docker-artifact: ${OUTPUT_PATH}"
	DOCKERBIN=$(PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" which docker)
	DOCKERPATH="${DOCKERBIN%${DOCKERBIN##*/}}"
	# generate the mender docker artifact
	if [ -n "${DOCKERPATH}" ]; then
		PATH="${DOCKERPATH}:$PATH" docker-artifact-gen -n ${ARTIFACT_NAME} -t ${MACHINE} -o ${OUTPUT_PATH} ${MENDER_ARTIFACT_DOCKERHUB_IMAGES} -- ${MENDER_ARTIFACT_EXTRA_ARGS}
	else
		docker-artifact-gen -n ${ARTIFACT_NAME} -t ${MACHINE} -o ${OUTPUT_PATH} ${MENDER_ARTIFACT_DOCKERHUB_IMAGES} -- ${MENDER_ARTIFACT_EXTRA_ARGS}
	fi
	if [ -f "$MENDER_ARTIFACT_SIGNING_KEY" ]; then
		mender-artifact sign ${OUTPUT_PATH} -k ${MENDER_ARTIFACT_SIGNING_KEY} -o ${ARTIFACT_NAME}.signed.mender
		install -m 644 ${B}/${ARTIFACT_NAME}.signed.mender ${DEPLOYDIR}/${ARTIFACT_NAME}.signed.mender
	fi
	install -m 644 ${B}/${OUTPUT_PATH} ${DEPLOYDIR}/${OUTPUT_PATH}
}

addtask deploy after do_packagedata do_package

PACKAGES = "${PN}"
