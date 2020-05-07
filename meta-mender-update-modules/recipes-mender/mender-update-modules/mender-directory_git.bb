HOMEPAGE = "https://mender.io"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7fd64609fe1bce47db0e8f6e3cc6a11d"
DESCRIPTION = "The docker Update Module installs a directory in the target."

SRC_URI = "git://github.com/mendersoftware/mender;protocol=https;branch=2.2.x"

SRCREV = "a59818d53952e7c191b0d99c5beddcbeadbb9104"

S = "${WORKDIR}/git"

inherit allarch

DEPENDS += "jq-native mender-docker-native"

SKIP_FILEDEPS_${PN} = "1"

do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install_class-native() {
    install -d ${D}/${bindir}
    install -m 755 ${S}/support/modules-artifact-gen/directory-artifact-gen ${D}/${bindir}/directory-artifact-gen
}

FILES_${PN}-class-native += "${bindir}/directory-artifact-gen"

BBCLASSEXTEND = "native"
