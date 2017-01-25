#
# Copyright (C) 2017 Wind River Systems Inc.
#

DESCRIPTION = "Linux Integrity Measurement Architecture (IMA) subsystem"

include packagegroup-ima.inc

RDEPENDS_${PN} += " \
    attr \
    key-store-ima-privkey \
    ima-evm-utils-evmctl.static \
"
