#!/usr/bin/env bash
#
# Copyright (C) 2021
#

# Main Env
KERNEL_ROOTDIR=$(pwd) # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_DEFCONFIG="vendor/ginkgo-perf_defconfig" # IMPORTANT ! Declare your kernel source defconfig file here.
PARENT_DIR="$(dirname "$KERNEL_DIR")"
TC="$PARENT_DIR/samsoeTC " # ganti samsoeTC menjadi toolchain yang digunakan
TG_TOKEN="TokenBot" # Teken bot
TG_CHAT_ID="-xxxxxx" # Chat id your telegram
ZIPNAME="nAa-240-Ginkgo-$(date '+%Y%m%d-%H%M').zip" # Nama file zip
#
# Letak bakal file yang slesai di compile
#
IMAGE="$PARENT_DIR/out/arch/arm64/boot/Image.gz-dtb"
DTBO="$PARENT_DIR/out/arch/arm64/boot/dtbo.img"
dts="$PARENT_DIR/out/arch/arm64/boot/dts/xiaomi/qcom-base/trinket.dts"

#Main Decoration
export KBUILD_BUILD_USER="Avina" # Change with your own name or else.
export KBUILD_BUILD_HOST="Unix"  # ganti sesuai selera
export TZ=":Asia/Jakarta" # Waktu yang digunakan
export PATH="$TC/bin:$PATH" # Path TC yang digunakan
export LD_LIBRARY_PATH="$TC/lib:$LD_LIBRARY_PATH" #Path untuk pelengkap
export KBUILD_COMPILER_STRING="$(dirname "$TC/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/' ")"

function check() {
#
#
if [ -d "AnyKernel" ]; then
echo -e "\nAnyKernel tidak ada.. Downloading . . .\n" 
git clone https://github.com/avinakefin/AnyKernel3 AnyKernel
else
echo -e "\nAny kernel sudah ada\n"
fi
if [ -d "samsoeTC" ]; then
echo -e "\nDownloading samsoe clang\n"
git clone https://github.com/avinakefin/SamsoeTC samsoeTC
else
echo -e "\nSamsoeTC sudah ada \n"
fi }

function post (){
# Telegram
BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}
tg_post_msg "
<b>Kernel Compiler</b>
======================
Builder Name : $KBUILD_BUILD_USER
Builder Host : $KBUILD_BUILD_HOST
Device : <code>Gingko Willow</code>
Clang Version : <code>${KBUILD_COMPILER_STRING}</code>
Fitur yang diujikan : 

isi pesan perubahan kernel disini
======================
<b>Jangan Lupa backup boot dan dtbo</b>
<code> Miui user rename trinket.dtb to dtb</code>"

}
# Post Main Information

# Compile
compile(){
	
cd ${KERNEL_ROOTDIR}
make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
make -j$(nproc) ARCH=arm64 O=out \
      ARCH=arm64 \
      CC="clang" \
      AR="llvm-ar" \
      NM="llvm-nm" \
      LD="ld.lld" \
      AS="llvm-as" \
      STRIP=llvm-strip \
      OBJCOPY="llvm-objcopy" \
      OBJDUMP="llvm-objdump" \
      CROSS_COMPILE=aarch64-linux-gnu- \
      CROSS_COMPILE_ARM32=arm-linux-gnueabi- 
}

# Push kernel to channel
function push() {
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build Selesai tanpa error Menggunakan : <code><b>$KBUILD_COMPILER_STRING</b></code> "
}

# Zipping
function zipping() {
    rm -f *zip
    cp $IMAGE AnyKernel
    cp $DTBO AnyKernel
    cp $dts AnyKernel
    cd AnyKernel
    zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
    cd ..
}
check
compile
post
zipping
push