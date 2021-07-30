#!/bin/bash -e
CC="$(pwd)/tools/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-"

# directory variables for easier maintainability
output_dir="$(pwd)/output"
patch_dir="$(pwd)/patches/kernel"
modules_dir="${output_dir}/modules"
headers_dir="${output_dir}/headers"
build_dir="${output_dir}/build"
linux_dir="${build_dir}/linux"
images_dir="${output_dir}/images"

# core count for compiling with -j
cores=$(( $(nproc) * 2 ))

# since we call these programs often, make calling them simpler
cross_make="make -C ${linux_dir} ARCH=arm CROSS_COMPILE=${CC}"


patches=""
release="${release:-v5.4}"


echo "Building kernel release: ${release}"
mkdir -p "${build_dir}"
mkdir -p "${images_dir}"

# check for the linux directory
if [ ! -d "${linux_dir}" ]; then
	echo "Getting ${release} kernel from https://github.com/torvalds/linux.."
	git -C ${build_dir} clone https://github.com/torvalds/linux.git
    git -C ${linux_dir} checkout ${release} -b tmp
fi

# always do a checkout to see if chosen kernel version has changed
#git -C ${linux_dir} checkout ${release} -b tmp

export KBUILD_BUILD_USER="jupiternano"
export KBUILD_BUILD_HOST="jupiternano"

echo "applying patches.."
cp patches/kernel/at91-sama5d27_jupiter_nano.dtsi ${linux_dir}/arch/arm/boot/dts/
cp patches/kernel/at91-sama5d27_jupiter_nano.dts ${linux_dir}/arch/arm/boot/dts/
cp patches/kernel/jupiter_nano_defconfig ${linux_dir}/arch/arm/configs
sed -i '50i at91-sama5d27_jupiter_nano.dtb \\' ${linux_dir}/arch/arm/boot/dts/Makefile


# Add wifi driver to source tree
rm -rf ${linux_dir}/drivers/staging/wilc1000
mkdir -p ${linux_dir}/drivers/staging/wilc1000
git clone https://github.com/linux4wilc/driver.git
mv driver/wilc/* ${linux_dir}/drivers/staging/wilc1000/
patch -d ${linux_dir} -p1 < patches/kernel/Kconfig.patch
patch -d ${linux_dir} -p1 < patches/kernel/Makefile.patch  
rm -rf driver


echo "preparing kernel.."
echo "cross_make: ${cross_make}"
#

if [ "$1" == "clean" ]; then
	${cross_make} distclean
fi

# only call with defconfig if a config file doesn't exist already
if [ ! -f "${linux_dir}/.config" ]; then
	${cross_make} jupiter_nano_defconfig
fi

# here we are grabbing the kernel version and release information from kbuild
built_version="$(${cross_make} --no-print-directory -s kernelversion 2>/dev/null)"
built_release="$(${cross_make} --no-print-directory -s kernelrelease 2>/dev/null)"

# build the dtb's, modules, and headers
DTC_FLAGS="-@" ${cross_make} dtbs -j"${cores}"
echo "copying kernel files"


# copy the kernel zImage and jupiter nano dtb to our images directory
cp ${linux_dir}/arch/arm/boot/dts/at91-sama5d27_jupiter_nano.dtb ${images_dir}/
echo "complete!"