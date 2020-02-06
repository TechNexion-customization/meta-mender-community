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
MENDERSETUP="$CWD/scripts/setup-environment"

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
  BUILDDIRECTORY=${BUILDDIRECTORY:-build-$MACHINE}
else
  BUILDDIRECTORY=${BUILDDIRECTORY:-build-$1}
fi
mender_build_dir=$CWD/$BUILDDIRECTORY

# Set up the basic yocto environment by sourcing fsl community's setup-environment bash script with/without TEMPLATECONF
if [ $TNCONFIGS -gt 0 -a -n "$MACHINE" -a -n "$DISTRO" ] ; then
  # TEMPLATECONF specifies where to get the bblayer and local conf samples
  TEMPLATECONF="$CWD/sources/meta-tn-imx-bsp/conf" MACHINE=$MACHINE DISTRO=$DISTRO source $YOCTOSETUP $BUILDDIRECTORY
else
  MACHINE=$MACHINE DISTRO=$DISTRO source $YOCTOSETUP $BUILDDIRECTORY
fi

# mender setup
if [ -z "$target" ]; then
  echo "Invalid target specified for mender setup"
  usage
  return 1
else
  if [ -f ./conf/mender_append_complete ]; then
    return 1
  fi
  # Common entries for Mender
  cat $mender_community_dir/templates/local.conf.append >> ./conf/local.conf

  # Board specific entries
  cp $target_templates/bblayers.conf.sample ./conf/bblayers.conf
  cat $target_templates/local.conf.append >> ./conf/local.conf

  touch ./conf/mender_append_complete
fi

