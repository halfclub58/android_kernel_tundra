#!/bin/bash
# gg.sh - Automatic kernel build script
# Make sure clang is added to your path before using this script.

# Prompt user for data
echo -e "Enter KBUILD_USER:"
read -rp "KBUILD_USER: " KBUILD_USER
echo -e "Enter KBUILD_HOST:"
read -rp "KBUILD_HOST: " KBUILD_HOST

# Set environment variables
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

# Set target parameters
TARGET_ARCH="arm64"
TARGET_SUBARCH="arm64"
TARGET_CC="clang"
TARGET_HOSTLD="ld.lld"
TARGET_CLANG_TRIPLE="aarch64-linux-gnu-"
TARGET_CROSS_COMPILE="aarch64-linux-gnu-"
TARGET_CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
THREAD="$(nproc --all)"
CC_ADDITIONAL_FLAGS="LLVM_IAS=1 LLVM=1 -Wno-error=unused-function"
TARGET_BUILD_USER="$KBUILD_USER"
TARGET_BUILD_HOST="$KBUILD_HOST"
TARGET_DTC_FLAGS="-q"
TARGET_OUT="../out"
TARGET_DEVICE="lahaina-qgki"

export TARGET_PRODUCT="$TARGET_DEVICE"

# Final kernel build parameters
FINAL_KERNEL_BUILD_PARA="ARCH=$TARGET_ARCH \
						 SUBARCH=$TARGET_SUBARCH \
						 HOSTLD=$TARGET_HOSTLD \
						 CC=$TARGET_CC \
						 CROSS_COMPILE=$TARGET_CROSS_COMPILE \
						 CROSS_COMPILE_COMPAT=$TARGET_CROSS_COMPILE_COMPAT \
						 CLANG_TRIPLE=$TARGET_CLANG_TRIPLE \
						 $CC_ADDITIONAL_FLAGS \
						 DTC_FLAGS=\"$TARGET_DTC_FLAGS\" \
						 -j$THREAD \
						 O=$TARGET_OUT \
						 TARGET_PRODUCT=$TARGET_DEVICE \
						 KBUILD_BUILD_USER=$TARGET_BUILD_USER \
						 KBUILD_BUILD_HOST=$TARGET_BUILD_HOST"

# Kernel target parameters
TARGET_KERNEL_FILE="$TARGET_OUT/arch/arm64/boot/Image"
TARGET_KERNEL_NAME="Kernel"
TARGET_KERNEL_MOD_VERSION="$(make kernelversion)"

# Defconfig parameters
DEFCONFIG_PATH="arch/arm64/configs"
DEFCONFIG_NAME="tundra_defconfig"

# Time parameters
START_SEC=$(date +%s)
CURRENT_TIME=$(date '+%Y%m%d-%H%M')

# Function to create default kernel configuration
make_defconfig() {
	echo -e "------------------------------"
	echo "Creating default kernel configuration..."
	echo -e "------------------------------"

	# Use only the defconfig name; Make сам підхопить його з configs/vendor
	make $FINAL_KERNEL_BUILD_PARA $DEFCONFIG_NAME ARCH=arm64 O=$TARGET_OUT || { echo -e "Failed to create default kernel configuration."; exit 1; }

	echo -e "Default kernel configuration created successfully."
}

# Function to build the kernel
build_kernel() {
	echo -e "------------------------------"
	echo "Building the kernel..."
	echo -e "------------------------------"
	make $FINAL_KERNEL_BUILD_PARA || { echo -e "Failed to build the kernel."; exit 1; }
	END_SEC=$(date +%s)
	COST_SEC=$(($END_SEC - $START_SEC))
	echo -e "Kernel build took $(($COST_SEC / 60))m $(($COST_SEC % 60))s"
}

# Clean function
clean() {
	echo -e "Cleaning source tree and build files..."
	make mrproper -j$THREAD > /dev/null 2>&1
	make clean -j$THREAD > /dev/null 2>&1
	rm -rf $TARGET_OUT
	echo -e "Clean completed."
}

# Kernel compilation function
compile_kernel() {
	clean
	make_defconfig
	build_kernel
}

# Run full kernel compilation
compile_kernel

echo -e "End."
