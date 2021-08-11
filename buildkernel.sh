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

ZIPNAME="Samsoe-240-Name-$(date '+%Y%m%d-%H%M').zip"

# ENV
CONFIG=vendor/ginkgo-perf_defconfig
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
KERN_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
KERN_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
export KBUILD_BUILD_USER="Avina@Unix"
export KBUILD_BUILD_HOST="Unix"
export TZ=":Asia/Jakarta"
export PATH="$PARENT_DIR/samsoeTc/bin:$PATH"
export LD_LIBRARY_PATH="$PARENT_DIR/samsoeTc/lib:$LD_LIBRARY_PATH"
export KBUILD_COMPILER_STRING="$(clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"

mkdir -p out
make O=out ARCH=arm64 vendor/ginkgo-perf_defconfig

if [[ $1 == "-r" || $1 == "--regen" ]]; then
cp out/.config arch/arm64/configs/vendor/ginkgo-perf_defconfig
echo -e "\nRegened defconfig succesfully!"
exit 0
else
echo -e "${bold}Compiling with CLANG${normal}\n$KBUILD_COMPILER_STRING"
make -j$(nproc --all) O=out ARCH=arm64 SUB_ARCH=arm64  CC=clang LD=ld.lld  AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img
fi

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n" 
git clone https://github.com/avinakefin/AnyKernel3 AnyKernel
cp $KERN_IMG AnyKernel
cp $KERN_DTBO AnyKernel
cp out/arch/arm64/boot/dts/xiaomi/qcom-base/trinket.dtb AnyKernel
cd AnyKernel
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel
rm -rf out
echo "Zip: $ZIPNAME"
curl --upload-file $ZIPNAME http://transfer.sh/$ZIPNAME; echo
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
else
echo -e "\nCompilation failed!"
fi
