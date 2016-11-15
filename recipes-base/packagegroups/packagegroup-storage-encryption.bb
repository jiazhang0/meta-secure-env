#
# Copyright (C) 2016 Wind River Systems Inc.
#

include packagegroup-storage-encryption.inc

DESCRIPTION = "The storage-encryption packages for rootfs."

# Install the minimal stuffs only for the linux rootfs.
# The common packages shared between initramfs and rootfs
# are listed in the .inc.
# @util-linux: fdisk
# @parted: parted
# @rng-tools: rngd
RDEPENDS_${PN} += " \
    util-linux-fdisk \
    parted \
    rng-tools \
"

RRECOMMENDS_${PN} += "kernel-module-tpm-rng"
