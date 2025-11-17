#! /bin/bash

#!!!!!!!!!!!!!!!!!!!!!!
#     Build Busybox
#!!!!!!!!!!!!!!!!!!!!!!

LLVM_PATH=/usr/lib/llvm-20/bin/
OUT_PATH=${HOME}/out/
INITRAMFS_PATH=${HOME}/out/initramfs

make none_defconfig

make -j$(nproc) \
    CC=${LLVM_PATH}clang HOSTCC=${LLVM_PATH}clang \
    LD=${LLVM_PATH}ld.lld NM=${LLVM_PATH}llvm-nm \
    RANLIB=${LLVM_PATH}llvm-ranlib STRIP=${LLVM_PATH}llvm-strip \
    OBJCOPY=${LLVM_PATH}llvm-objcopy OBJDUMP=${LLVM_PATH}llvm-objdump

make CONFIG_PREFIX=${OUT_PATH}/busybox/_install install \
    CC=${LLVM_PATH}clang HOSTCC=${LLVM_PATH}clang \
    LD=${LLVM_PATH}ld.lld NM=${LLVM_PATH}llvm-nm \
    RANLIB=${LLVM_PATH}llvm-ranlib STRIP=${LLVM_PATH}llvm-strip \
    OBJCOPY=${LLVM_PATH}llvm-objcopy OBJDUMP=${LLVM_PATH}llvm-objdump

mkdir -p ${OUT_PATH}/initramfs/{bin,sbin,etc,proc,sys,dev,usr/bin,usr/sbin}
cp -a ${OUT_PATH}/busybox/_install/* ${OUT_PATH}/initramfs/

cat > ${OUT_PATH}/initramfs/init <<EOF
#!/bin/sh
mount -t devtmpfs devtmpfs /dev 2>/devnull || busybox mdev -s
mount -t proc proc /proc
mount -t sysfs sysfs /sys

echo "[None] bootup"

mkdir /newroot
mount -t ext4 /dev/vda /newroot
exec switch_root /newroot /sbin/init
exec /bin/sh
EOF

chmod +x  ${OUT_PATH}/initramfs/init

sudo mknod -m 600 ${OUT_PATH}/initramfs/dev/console c 5 1
sudo mknod -m 666 ${OUT_PATH}/initramfs/dev/null    c 1 3