#
# Copyright (C) 2017 Wind River Systems Inc.
#

DESCRIPTION = "Linux Integrity Measurement Architecture (IMA) subsystem"

include packagegroup-ima.inc

RDEPENDS_${PN} += " \
    key-store-ima-privkey \
"
