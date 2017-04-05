#
# Copyright (C) 2016 Wind River Systems Inc.
#

include packagegroup-storage-encryption.inc

DESCRIPTION = "The storage-encryption packages for initramfs."

RDEPENDS_${PN} += " \
    cryptfs-tpm2-initramfs-script \
"
