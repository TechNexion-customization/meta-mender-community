DESCRIPTION = "The dfu Update Module installs a firmware file in the target."

require mender-update-modules.inc

inherit allarch

do_install_class-target() {
    install -d ${D}/${datadir}/mender/modules/v3
    install -m 755 ${S}/dfu/module/dfu ${D}/${datadir}/mender/modules/v3/dfu
}

do_install_class-native() {
    install -d ${D}/${bindir}
    install -m 755 ${S}/dfu/module-artifact-gen/dfu-artifact-gen ${D}/${bindir}/dfu-artifact-gen
}

FILES_${PN} += "${datadir}/mender/modules/v3/dfu"
FILES_${PN}-class-native += "${bindir}/dfu-artifact-gen"

BBCLASSEXTEND = "native"
