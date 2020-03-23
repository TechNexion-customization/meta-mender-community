# Mender integration for TechNexion based boards

# Reuses mender-setup-imx.bbclass from meta-mender-imx meta layer

Supported boards:

 - Pico-Pi i.MX7D
 - Pico-Pi i.MX6
 - Pico-Pi i.MX8MQ
 - Pico-Pi i.MX8MM

## Build

Download the source:

    $ mkdir technexion
    $ cd technexion
    $ repo init \
           -u https://github.com/mendersoftware/meta-mender-community \
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

