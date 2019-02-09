#!/bin/bash                                                                                                                                 
# restart script with root privileges if not already
[ "$UID" -eq 0 ] || exec sudo "$0" "$@" ]

output_dir="$(pwd)/output"
rootfs_dir="${output_dir}/rootfs"
mkdir -p ${rootfs_dir}

debootstrap \
		--include ca-certificates,python3-setuptools,python3-pip,sudo \
        --arch armhf \
        --foreign stretch \
        ${rootfs_dir} \
        http://ftp.us.debian.org/debian/

cp /usr/bin/qemu-arm-static ${rootfs_dir}/usr/bin/
cp scripts/chroot.sh ${rootfs_dir}

mkdir -p ${rootfs_dir}/run
chmod -R 755 ${rootfs_dir}/run
mount -t tmpfs run "${rootfs_dir}/run"

chroot ${rootfs_dir} /debootstrap/debootstrap --second-stage

mount -t sysfs sysfs "${rootfs_dir}/sys"
mount -t proc proc "${rootfs_dir}/proc"
mkdir -p ${rootfs_dir}/dev/pts
mount -t devpts devpts "${rootfs_dir}/dev/pts"

chroot "${rootfs_dir}" /bin/bash -e chroot.sh

sync

umount -fl "${rootfs_dir}/dev/pts"
umount -fl "${rootfs_dir}/proc"
umount -fl "${rootfs_dir}/sys"
umount -fl "${rootfs_dir}/run"

rm ${rootfs_dir}/usr/bin/qemu-arm-static

tar -C ${rootfs_dir} -czf ${output_dir}/rootfs.tar.gz .
