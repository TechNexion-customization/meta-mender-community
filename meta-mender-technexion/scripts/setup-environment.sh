#!/bin/sh -x -e

# this script setups up the mender build envrionment
# for technexion boards

if [ -n "$BASH_SOURCE" ]; then
    this_script=$BASH_SOURCE
elif [ -n "$ZSH_NAME" ]; then
    this_script=$0
else
    this_script="$(pwd)/setup-environment"
fi

CWD=$(pwd)
YOCTOSETUP="$CWD/sources/meta-tn-imx-bsp/tools/setup-environment.sh"
QTSETUP="$CWD/sources/meta-boot2qt/scripts/setup-environment.sh"
MENDERSETUP="$CWD/sources/poky/oe-init-build-env"

TNCONFIGS=0
if [ -n "$MACHINE" ]; then
  TNCONFIGS=$(ls $CWD/sources/meta-tn-imx-bsp/conf/machine/*.conf | xargs -n 1 basename | grep -E -c "$MACHINE")
fi
MENDERCONFIGS=(
    "atmel"
    "beaglebone"
    "intel"
    "nxp"
    "qemu"
    "raspberrypi"
    "renesas"
    "rockchip"
    "sunxi"
    "technexion"
    "tegra"
    "up"
    "variscite")
target=""

usage ()
{
  echo "Usage: [MACHINE=???] [DISTRO=???] source $0 [target|build_directory]"
  echo "Supported targets are:"
  echo "    ${MENDERCONFIGS[@]}"
  echo "    anything else is treated as build directory"
}

if [ $? != 0 -o $# -lt 1 ]; then
  usage
  return 1
fi

while test -n "$1"; do
  case "$1" in
    "--help" | "-h")
      usage
      return 0
      ;;
    *)
      for conf in ${MENDERCONFIGS[@]}
      do
        if [ "$conf" = "$1" ] ; then
          target=$1
          break
        fi
      done
      ;;
  esac
  shift
done

THIS_SCRIPT="setup-environment"
if [ "$(basename -- $0)" = "$THIS_SCRIPT" ]; then
  # setup-environment are to be sourced only
  echo "Error: This script needs to be sourced. Please run as '. $0' or 'source $0'"
  return 1
fi

mender_community_dir=$CWD/sources/meta-mender-community
target_templates=$mender_community_dir/meta-mender-${target}/templates
if [ -n "$MACHINE" ]; then
  BUILDDIRECTORY="build-$MACHINE"
else
  BUILDDIRECTORY="build"
fi
mender_build_dir=$CWD/$BUILDDIRECTORY

# Check if MACHINE and DISTRO are already in previous setup
EXISTING="no"
if [ -f $mender_build_dir/conf/local.conf ]; then
  case "$DISTRO" in
  "b2qt")
    if grep -q "MACHINE_HOSTNAME.*b2qt" $mender_build_dir/conf/local.conf; then
      if grep -q "DISTRO.*b2qt" $mender_build_dir/conf/local.conf; then
        EXISTING="has"
      fi
    fi
    ;;
  "virtualization")
    if grep -q "MACHINE ??= '${MACHINE}'" $mender_build_dir/conf/local.conf; then
      if grep -Fq "BBMULTICONFIG = \"container\"" $mender_build_dir/conf/local.conf; then
        if [ -d $CWD/sources/meta-virtualization ]; then
          EXISTING="has"
        fi
      fi
    fi
    ;;
  *)
    if grep -q "MACHINE ??= '${MACHINE}'" $mender_build_dir/conf/local.conf; then
      if grep -q "DISTRO ?= '${DISTRO}'" $mender_build_dir/conf/local.conf; then
        if [ ! -d $CWD/sources/meta-virtualization ]; then
          EXISTING="has"
        fi
      fi
    fi
    ;;
  esac
fi
echo "$EXISTING existing configuration..."

#
# Set up the basic yocto environment by sourcing fsl community's setup-environment bash script with/without TEMPLATECONF
# Only remove and reset the build environment when there is none or previous
# configuration is different
#
if [ $TNCONFIGS -gt 0 -a -n "$MACHINE" -a -n "$DISTRO" ] ; then
  case "$DISTRO" in
  "b2qt")
    if [ "$EXISTING" = "no" ]; then
      # copy local_manifest_b2qt.xml to .repo/local_manifests/
      rm -rf ./build-$MACHINE/
      rm -rf .repo/local_manifests/*overrides.xml
      mkdir -p .repo/local_manifests
      cp sources/meta-mender-community/meta-mender-technexion/scripts/manifest-b2qt-overrides.xml .repo/local_manifests
      # and repo sync --force-sync to update boot2qt repositories and layers
      repo sync --force-sync
    fi
    # finally setup the boot2qt build directory
    echo "Setup Boot2qt:"
    echo "    export MACHINE=$MACHINE"
    echo "    source $QTSETUP"
    echo ""
    export MACHINE=$MACHINE
    source $QTSETUP
    ;;
  "virtualization")
    if [ "$EXISTING" = "no" ]; then
      # copy local_manifest_b2qt.xml to .repo/local_manifests/
      rm -rf ./build-$MACHINE/
      rm -rf .repo/local_manifests/*overrides.xml
      mkdir -p .repo/local_manifests
      cp sources/meta-mender-community/meta-mender-technexion/scripts/manifest-virtualization-overrides.xml .repo/local_manifests
      # and repo sync --force-sync to update boot2qt repositories and layers
      repo sync --force-sync
      case "$MACHINE" in
      *imx6ul)
        DIST="fsl-imx-x11"
        ;;
      *imx6)
        DIST="fsl-imx-x11"
        ;;
      *imx7)
        DIST="fsl-imx-x11"
        ;;
      *)
        DIST="fsl-imx-xwayland"
        ;;
      esac
    fi
    # finally setup the yocto build directory
    echo "Setup Virtualization/Container:"
    echo "    TEMPLATECONF=$CWD/sources/meta-tn-imx-bsp/conf MACHINE=$MACHINE DISTRO=$DIST source $YOCTOSETUP $BUILDDIRECTORY"
    echo ""
    TEMPLATECONF="$CWD/sources/meta-tn-imx-bsp/conf" MACHINE=$MACHINE DISTRO=$DIST source $YOCTOSETUP $BUILDDIRECTORY
    ;;
  *)
    if [ "$EXISTING" = "no" ]; then
      # clears .repo/local_manifests/ (and local_manifest_b2qt.xml)
      rm -rf ./build-$MACHINE/
      rm -rf .repo/local_manifests/*overrides.xml
      # and repo sync --force-sync to source repositories
      repo sync --force-sync
    fi
    # finally setup the yocto build directory
    echo "Setup Yocto:"
    echo "    TEMPLATECONF=$CWD/sources/meta-tn-imx-bsp/conf MACHINE=$MACHINE DISTRO=$DISTRO source $YOCTOSETUP $BUILDDIRECTORY"
    echo ""
    # TEMPLATECONF specifies where to get the bblayer and local conf samples
    TEMPLATECONF="$CWD/sources/meta-tn-imx-bsp/conf" MACHINE=$MACHINE DISTRO=$DISTRO source $YOCTOSETUP $BUILDDIRECTORY
    ;;
  esac
else
  echo "Setup Mender:"
  echo "    source $MENDERSETUP $BUILDDIRECTORY"
  echo ""
  source $MENDERSETUP $BUILDDIRECTORY
fi

# mender setup
if [ -z "$target" ]; then
  echo "Invalid target specified for mender setup"
  usage
  return 1
else
  if [ -f ${mender_build_dir}/conf/mender_append_complete ]; then
    return 1
  fi
  # Common entries for Mender
  cat $mender_community_dir/templates/local.conf.append >> ${mender_build_dir}/conf/local.conf

  # Board specific entries
  case "$DISTRO" in
  "b2qt")
    if [ "$EXISTING" = "no" ]; then
      cp $target_templates/bblayers.conf.sample.b2qt ${mender_build_dir}/conf/bblayers.conf
      cat $target_templates/local.conf.append.b2qt >> ${mender_build_dir}/conf/local.conf
    fi
    if ! grep -Fq "meta-tn-imx-bsp/recipes-containers/docker-disk/docker-disk.bb" ${mender_build_dir}/conf/local.conf; then
      echo "BBMASK += \"meta-tn-imx-bsp/recipes-containers/docker-disk/docker-disk.bb\"" >> ${mender_build_dir}/conf/local.conf
    fi
    if ! grep -Fq "meta-tn-imx-bsp/recipes-containers/docker/docker_%.bbappend" ${mender_build_dir}/conf/local.conf; then
      echo "BBMASK += \"meta-tn-imx-bsp/recipes-containers/docker/docker_%.bbappend\"" >> ${mender_build_dir}/conf/local.conf
    fi
    if ! grep -Fq "meta-tn-imx-bsp/recipes-graphics/wayland/weston_%.bbappend" ${mender_build_dir}/conf/local.conf; then
      echo "BBMASK += \"meta-tn-imx-bsp/recipes-graphics/wayland/weston_%.bbappend\"" >> ${mender_build_dir}/conf/local.conf
    fi
    if ! grep -Fq "meta-tn-imx-bsp/recipes-qt/qt5/qtbase_%.bbappend" ${mender_build_dir}/conf/local.conf; then
      echo "BBMASK += \"meta-tn-imx-bsp/recipes-qt/qt5/qtbase_%.bbappend\"" >> ${mender_build_dir}/conf/local.conf
    fi
    if ! grep -Fq "meta-mender-community/meta-mender-technexion/recipes-containers/docker-disk/docker-disk.bbappend" ${mender_build_dir}/conf/local.conf; then
      echo "BBMASK += \"meta-mender-community/meta-mender-technexion/recipes-containers/docker-disk/docker-disk.bbappend\"" >> ${mender_build_dir}/conf/local.conf
    fi
    if ! grep -Fq "meta-mender-community/meta-mender-technexion/recipes-core/images/tn-image-docker-os.bbappend" ${mender_build_dir}/conf/local.conf; then
      echo "BBMASK += \"meta-mender-community/meta-mender-technexion/recipes-core/images/tn-image-docker-os.bbappend\"" >> ${mender_build_dir}/conf/local.conf
    fi
    ;;
  "virtualization")
    if [ "$EXISTING" = "no" ]; then
      cp $target_templates/bblayers.conf.sample.virtualization ./conf/bblayers.conf
      cat $target_templates/local.conf.append.virtualization >> ./conf/local.conf
    fi
    ;;
  *)
    if [ "$EXISTING" = "no" ]; then
      cp $target_templates/bblayers.conf.sample ./conf/bblayers.conf
      cat $target_templates/local.conf.append >> ./conf/local.conf
    fi
    if ! grep -Fq "meta-mender-community/meta-mender-technexion/recipes-containers/docker-disk/docker-disk.bbappend" ${mender_build_dir}/conf/local.conf; then
      echo "BBMASK += \"meta-mender-community/meta-mender-technexion/recipes-containers/docker-disk/docker-disk.bbappend\"" >> ${mender_build_dir}/conf/local.conf
    fi
    ;;
  esac

  touch ${mender_build_dir}/conf/mender_append_complete
fi

