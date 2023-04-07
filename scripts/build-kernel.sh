#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p build && cd build

# Download and patch the orange pi linux kernel source
if [ ! -d linux-orangepi ]; then
    git clone --progress -b orange-pi-5.10-rk3588 https://github.com/orangepi-xunlong/linux-orangepi.git
    git -C linux-orangepi checkout 0d1781e72fb7707a0bbc4419c8f1bc75a113f19a
    for patch in ../patches/linux-orangepi/*.patch; do git -C linux-orangepi apply "../${patch}"; done
fi
cd linux-orangepi

# Set kernel config 
cp ../../config/linux-rockchip-rk3588-legacy.config .config
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
./scripts/config --disable CONFIG_DEBUG_INFO
./scripts/config --disable CONFIG_MODULE_SCMVERSION

touch .version

# Compile kernel into deb package
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KBUILD_DEBARCH=arm64 KDEB_PKGVERSION="5.10.110-1" LOCALVERSION="-rockchip-rk3588" -j "$(nproc)" bindeb-pkg

rm -f ../*.buildinfo ../*.changes ../linux-libc-dev*
