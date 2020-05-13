# Mender integration for TechNexion based boards

# Reuses mender-setup-imx.bbclass from meta-mender-imx meta layer

Supported boards:

 - Pico-Pi i.MX8MM

## Build

Download the source:

    $ mkdir technexion
    $ cd technexion
    $ repo init \
           -u https://github.com/TechNexion-customization/meta-mender-community \
           -m meta-mender-technexion/scripts/manifest-technexion.xml \
           -b sumo
    $ repo sync

For building base image:
Setup:
    $ MACHINE=pico-imx8mm DISTRO=fsl-imx-xwayland source setup-environment technexion
Build:
    $ bitbake core-image-base

For building yocto test image:
Setup:
    $ MACHINE=pico-imx8mm DISTRO=fsl-imx-xwayland source setup-environment technexion
Build:
    $ bitbake fsl-image-qt5-validation-imx

For building b2qt image:
Setup:
    $ export MACHINE=pico-imx8mm
    $ MACHINE=pico-imx8mm DISTRO=b2qt source setup-environment technexion
Build:
    $ bitbake b2qt-embedded-qt5-image

For building TechNexion Container OS image:
Setup:
    $ MACHINE=pico-imx8mm DISTRO=virtualization source setup-environment technexion
Build:
    $ bitbake tn-image-docker-os

## NOTE

### Storage Partitions in Mender:

Mender uses its own wks file to prepare sdimg image file. The wks file is generated in mender_part_image() function from mender-part-images.bbclass. Mender calculate partition sizes from MENDER variables specified in local.conf.

i.e.
- MENDER_STORAGE_TOTAL_SIZE_MB ?= "8176"
- MENDER_BOOT_PART_SIZE_MB = "20"
- MENDER_DATA_PART_SIZE_MB = "4080"
- Mender's each rootfs size is calculated from
MENDER_STORAGE_TOTAL_SIZE_MB - MENDER_BOOT_PART_SIZE_MB - MENDER_DATA_PART_SIZE_MB) / 2

### Storage Partitions in Technexion Container OS:
TechNexion uses tn-imx8-imxboot-rootfs-container.wks.in wks file to prepare wic image for docker container os (an yocto with ready-built dockerd engine). The wks file describes following storage partition format
1. SPL+imx-boot from 33KB address of RAW data
2. Boot partition starting from calculated aligned address of FAT32 filesystem
3. Rootfs partition after Boot partition of EXT4 filesystem
4. Docker data partition after Rootfs partition of 2GB mounted to /var/lib/docker of EXT4 filesystem

**Careful planning must be considered for TechNexion Container OS with Mender support, where there are no additional data partition defined for dockerd engine to store downloaded images (i.e. in /var/lib/docker). One must calculate a suitable roofs partition size to hold expected docker container images for TechNexion Container OS with Mender Support.**
