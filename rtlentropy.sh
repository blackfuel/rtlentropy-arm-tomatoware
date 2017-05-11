#!/bin/bash
#############################################################################
# rtl-entropy for Tomatoware
#
# This script downloads and compiles all packages needed for adding 
# hardware RNG capability to Asus ARM routers.
#
# Before running this script, you must first compile your router firmware so
# that it generates the AsusWRT libraries.  Do not "make clean" as this will
# remove the libraries needed by this script.
#############################################################################
PATH_CMD="$(readlink -f $0)"

set -e
set -x

#REBUILD_ALL=0
PACKAGE_ROOT="/mmc"
SRC="/mmc/src/rtl-entropy"
PATH_MMC=/mmc/usr/bin:/mmc/usr/local/sbin:/mmc/usr/local/bin:/mmc/usr/sbin:/mmc/usr/bin:/mmc/sbin:/mmc/bin
PATH_OLD=$PATH
PATH=$PATH_MMC
#MAKE="make -j`nproc`"
MAKE="make -j1"

########## ##################################################################
# LIBCAP # ##################################################################
########## ##################################################################

DL="libcap-2.25.tar.gz"
URL="http://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/$DL"
mkdir -p $SRC/libcap && cd $SRC/libcap
FOLDER="${DL%.tar.gz*}"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

if [ ! -f "libcap/include/linux/xattr.h" ]; then
  mkdir -p libcap/include/linux
  cp -p "${PATH_CMD%/*}/asuswrt-kernel-headers/linux/xattr.h" libcap/include/linux
fi

cd libcap
PATH=$PATH_OLD
$MAKE _makenames
PATH=$PATH_MMC
cd ..

$MAKE install \
DESTDIR="$PACKAGE_ROOT" \
prefix="" \
INDENT="| true" \
PAM_CAP="no" \
RAISE_SETFCAP="no" \
DYNAMIC="yes" \
lib="lib"

touch __package_installed
fi

########## ##################################################################
# LIBUSB # ##################################################################
########## ##################################################################

URL="https://github.com/libusb/libusb.git"
FOLDER="${URL##*/}"
FOLDER="${FOLDER%.*}"
DL="${FOLDER}.tar.gz"
mkdir -p $SRC/libusb && cd $SRC/libusb
[ "$REBUILD_ALL" == "1" ] && rm -rf "$DL" "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && rm -rf "$FOLDER" && git clone $URL && tar czvf $DL $FOLDER
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

[ ! -f "configure" ] && autoreconf -i

PKG_CONFIG_PATH="$PACKAGE_ROOT/lib/pkgconfig" \
./configure \
--prefix="$PACKAGE_ROOT" \
--enable-static \
--enable-shared \
--disable-udev \
--disable-log \
--disable-silent-rules

$MAKE
make install
touch __package_installed
fi

########### #################################################################
# RTL-SDR # #################################################################
########### #################################################################

URL="git://git.osmocom.org/rtl-sdr.git"
FOLDER="${URL##*/}"
FOLDER="${FOLDER%.*}"
DL="${FOLDER}.tar.gz"
mkdir -p $SRC/rtl-sdr && cd $SRC/rtl-sdr
[ "$REBUILD_ALL" == "1" ] && rm -rf "$DL" "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && rm -rf "$FOLDER" && git clone $URL && tar czvf $DL $FOLDER
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

[ ! -f "configure" ] && autoreconf -i

PKG_CONFIG_PATH="$PACKAGE_ROOT/lib/pkgconfig" \
./configure \
--prefix="$PACKAGE_ROOT" \
--enable-static \
--enable-shared \
--disable-silent-rules

$MAKE
make install
touch __package_installed
fi

############### #############################################################
# RTL-ENTROPY # #############################################################
############### #############################################################

URL="https://github.com/pwarren/rtl-entropy.git"
FOLDER="${URL##*/}"
FOLDER="${FOLDER%.*}"
DL="${FOLDER}.tar.gz"
mkdir -p $SRC/rtl-entropy && cd $SRC/rtl-entropy
[ "$REBUILD_ALL" == "1" ] && rm -rf "$DL" "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && rm -rf "$FOLDER" && git clone $URL && tar czvf $DL $FOLDER
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

rm -rf build
mkdir -p build
cd build

cmake \
-DCMAKE_INSTALL_PREFIX="$PACKAGE_ROOT" \
-DCMAKE_PREFIX_PATH="$PACKAGE_ROOT" \
-DCMAKE_VERBOSE_MAKEFILE=TRUE \
../

$MAKE
make install
touch ../__package_installed
fi

