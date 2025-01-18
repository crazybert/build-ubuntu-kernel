#!/bin/bash

# Compile the Linux kernel for Ubuntu.

set -euo pipefail

KERNEL_MAJOR_VER=${KERNEL_MAJOR_VER:-"6"}
KERNEL_BASE_VER=${KERNEL_BASE_VER:-"6.12"}
KERNEL_PATCH_VER=${KERNEL_PATCH_VER:-"6.12.3"}
KERNEL_SUB_VER=${KERNEL_SUB_VER:-"061203"}
KERNEL_TYPE=${KERNEL_TYPE:-"idle"}
KERNEL_VERSION_LABEL=${KERNEL_VERSION_LABEL:-"custom"}

KERNEL_MAIN_DIR=${KERNEL_MAIN_DIR:-$HOME/kernel_main}
KERNEL_BUILD_DIR=${KERNEL_BUILD_DIR:-${KERNEL_MAIN_DIR}/build}
KERNEL_SOURCES_DIR=${KERNEL_SOURCES_DIR:-${KERNEL_MAIN_DIR}/sources}
COMPILED_KERNELS_DIR=${COMPILED_KERNELS_DIR:-${KERNEL_MAIN_DIR}/compiled}
CONFIG_PATH=${CONFIG_PATH:-${KERNEL_MAIN_DIR}/configs}
KERNEL_SRC_URI=${KERNEL_SRC_URI:-"https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR_VER}.x"}
KERNEL_SRC_EXT=${KERNEL_SRC_EXT:-"tar.xz"}
KERNEL_SRC_NAME=${KERNEL_SRC_NAME:-"linux-${KERNEL_PATCH_VER}"}
KERNEL_SRC_URL=${KERNEL_SRC_URL:-${KERNEL_SRC_URI}/${KERNEL_SRC_NAME}.${KERNEL_SRC_EXT}}

ZFS_TAG=${ZFS_TAG:-"zfs-2.3.0"}

ZFS_BUILD_DIR=${KERNEL_BUILD_DIR}/${ZFS_TAG}-${KERNEL_PATCH_VER}-${KERNEL_SUB_VER}+${KERNEL_VERSION_LABEL}

cd ${KERNEL_SOURCES_DIR}

if [ -d zfs ]; then
    cd zfs
    git pull
else
    echo "*** Fetching openzfs... ✓";
    git clone https://github.com/openzfs/zfs
fi

mkdir -p ${KERNEL_BUILD_DIR}
rm -rf ${ZFS_BUILD_DIR}
cp -r ${KERNEL_SOURCES_DIR}/zfs ${ZFS_BUILD_DIR}
cd ${ZFS_BUILD_DIR}
git checkout ${ZFS_TAG}
sed -i 's/Depends: linux-image-_KVERS_ | raspberrypi-kernel/Depends: linux-image-_KVERS_ | linux-image-unsigned-_KVERS_ | raspberrypi-kernel/g' ./contrib/debian/control.modules.in;
KVERS=${KERNEL_PATCH_VER}-${KERNEL_SUB_VER}-generic

#WITH_LINUX=~/kernel_main/build/linux-6.12.9/debian/build/build-generic/__________________dkms/headers/linux-headers-6.12.9-061209+customidle-generic
#WITH_LINUX=kernel_main/build/linux-6.12.9/debian/build/build-generic
WITH_LINUX=/usr/src/linux-headers-${KVERS}
WITH_LINUX_OBJ=${WITH_LINUX}
KSRC=${WITH_LINUX}
KOBJ=${WITH_LINUX}
./autogen.sh
./configure --with-linux=${WITH_LINUX} --with-linux-obj=${WITH_LINUX_OBJ}
KSRC=${KSRC} KOBJ=${KOBJ} make native-deb
