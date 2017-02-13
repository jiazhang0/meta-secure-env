#
# Copyright (C) 2017 Wind River Systems Inc.
#

DESCRIPTION = "Linux Integrity Measurement Architecture (IMA) subsystem"

include packagegroup-ima.inc

DEPENDS += " \
    ima-evm-utils-native \
    attr-native \
"

RDEPENDS_${PN} += " \
    attr \
    util-linux-switch_root.static \
    attr-setfattr.static \
    ima-evm-utils-evmctl.static \
"

# Note IMA private key is not available if user key signing model used.
RRECOMMENDS_${PN} += "key-store-ima-privkey"
