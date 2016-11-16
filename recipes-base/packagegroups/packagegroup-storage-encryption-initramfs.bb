#
# Copyright (C) 2016 Wind River Systems Inc.
#

include packagegroup-storage-encryption.inc

DESCRIPTION = "The storage-encryption packages for initramfs."

# Install the minimal stuffs only for the linux rootfs.
# The common packages shared between initramfs and rootfs
# are listed in the .inc.
ROOTFS_BOOTSTRAP_INSTALL += " \
    cryptfs-tpm2 \
"
