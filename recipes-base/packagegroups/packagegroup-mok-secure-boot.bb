#
# Copyright (C) 2016 Wind River Systems Inc.
#

DESCRIPTION = "Mok secure boot packages for secure-environment."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

ALLOW_EMPTY_${PN} = "1"
ALLOW_EMPTY_${PN}-net = "1"

# Packages added by/for the secure-environment layer
pkgs = " \
    shim \
    mokutil \
    packagegroup-uefi-secure-boot \
"

RDEPENDS_${PN}_x86 = "${pkgs}"
RDEPENDS_${PN}_x86-64 = "${pkgs}"
