#
# Copyright (C) 2016 Wind River Systems Inc.
#

DESCRIPTION = "Linux Integrity Measurement Architecture (IMA) subsystem for initramfs"

include packagegroup-ima.inc

RDEPENDS_${PN} += " \
    keyutils \
    ima-policy \
    util-linux-switch_root.static \
"
