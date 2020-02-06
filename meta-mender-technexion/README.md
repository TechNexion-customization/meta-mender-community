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
           -m meta-mender-tn/scripts/manifest-technexion.xml \
           -b sumo
    $ repo sync

Setup environment

    $ . setup-environment technexion

Build

    $ bitbake core-image-base
