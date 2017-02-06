#
# Copyright (C) 2017 Wind River Systems Inc.
#

DESCRIPTION = "Linux Integrity Measurement Architecture (IMA) subsystem"

include packagegroup-ima.inc

RDEPENDS_${PN} += " \
    attr \
    ima-evm-utils-evmctl.static \
"

# Note IMA private key is not available if user key signing model used.
RRECOMMENDS_${PN} += "key-store-ima-privkey"
