#!/usr/bin/env bash
#
#
# Simple Local Kernel Build Script
#
# Setup build env with akhilnarang/scripts repo
#
# Use this script on root of kernel directory

bold=$(tput bold)
normal=$(tput sgr0)

# Scrip option
while (( ${#} )); do
    case ${1} in
        "-Z"|"--zip") ZIP=true ;;
    esac
    shift
done


[[ -z ${ZIP} ]] && { echo "${bold}Gunakan -Z atau --zip Untuk Membuat Zip Kernel Installer${normal}"; }


# ENV
CONFIG=vendor/ginkgo-perf_defconfig
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
KERN_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
KERN_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
export KBUILD_BUILD_USER="Avina"
export KBUILD_BUILD_HOST="Unix"
export TZ=":Asia/Jakarta"
export PATH="$PARENT_DIR/samsoe/bin:$PATH"
export LD_LIBRARY_PATH="$PARENT_DIR/samsoe/lib:$LD_LIBRARY_PATH"
export KBUILD_COMPILER_STRING="$($PARENT_DIR/samsoe/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"

# Functions
clang_build () {
    make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img
}

mkdir -p out
make O=out ARCH=arm64 vendor/ginkgo-perf_defconfig

if [[ $1 == "-r" || $1 == "--regen" ]]; then
cp out/.config arch/arm64/configs/vendor/ginkgo-perf_defconfig
echo -e "\nRegened defconfig succesfully!"
exit 0
else
echo -e "${bold}Compiling with CLANG${normal}\n$KBUILD_COMPILER_STRING"
make -j$(nproc --all) O=out ARCH=arm64 SUB_ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img
fi
#clang_build

if ! [ -a "$KERN_IMG" ]; then
    echo "${bold}Build error, Tolong Perbaiki Masalah Ini${normal}"
    exit 1
fi

[[ -z ${ZIP} ]] && { exit; }

# clone AnyKernel3
if ! [ -d "AnyKernel3" ] ; then
    git clone https://github.com/avinakefin/AnyKernel3 Anykernel
else
    echo "${bold}Direktori Anykernel Sudah Ada"
fi

# ENV
ZIP_DIR=$KERNEL_DIR/Anykernel
VENDOR_MODULEDIR="$ZIP_DIR/modules/vendor/lib/modules"
STRIP="aarch64-linux-gnu-strip"

# Make zip
make -C "$ZIP_DIR" clean
wifi_modules
cp "$KERN_IMG" "$ZIP_DIR"/
cp "$KERN_DTBO" "$ZIP_DIR"/
make -C "$ZIP_DIR" normal
