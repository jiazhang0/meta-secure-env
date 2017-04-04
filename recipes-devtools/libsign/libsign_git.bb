#
# Copyright (C) 2017 Wind River Systems, Inc.
#

SUMMARY = "A generic signing tool framework"
DESCRIPTION = " \
This project targets to provide a generic signing framework. This framework \
separates the signing request and signing process and correspondingly forms \
the so-called signlet and signaturelet. \
Each signaturelet only concerns about the details about how to construct the \
layout of a signature format, and signlet only cares how to construct the \
signing request. \
"
SECTION = "devel"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=8cdfce2a54b8b37c990425e4a8a84f66"

SRC_URI = " \
    git://github.com/jiazhang0/libsign.git \
"
SRCREV = "${AUTOREV}"
PV = "0.3.1+git${SRCPV}"

DEPENDS += "openssl"
RDEPENDS_${PN}_class-target += "libcrypto"

PARALLEL_MAKE = ""

S = "${WORKDIR}/git"

EXTRA_OEMAKE = " \
    prefix="${prefix}" \
    sbindir="${sbindir}" \
    libdir="${libdir}" \
    includedir="${includedir}" \
    CC="${CC}" \
    EXTRA_CFLAGS="${CFLAGS}" \
    EXTRA_LDFLAGS="${LDFLAGS}" \
"

do_install() {
    oe_runmake install DESTDIR="${D}"
}

FILES_${PN} = "\
    ${sbindir} \
    ${libdir} \
"

BBCLASSEXTEND="native"
