#
# Copyright (C) 2016 Wind River Systems, Inc.
#
SUMMARY = "RPM public key import service"
DESCRIPTION = "This is a startup systemd service to import the public RPM key \
 into the system. \
"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

inherit systemd

FILESEXTRAPATHS_prepend := "${THISDIR}:"

SRC_URI = " \
    file://source/COPYING \
    file://source/rpm-import-key.service \
"

S = "${WORKDIR}"

do_install() {
    install -d -m 0755 ${D}/etc
    install -m 0600 ${RPM_PUBLIC_KEY} ${D}/etc/pub.key
    # systemd services
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/source/rpm-import-key.service ${D}${systemd_unitdir}/system/
}

PACKAGES =+ "${PN}-systemd"
RDEPENDS_${PN}-systemd += "${PN}"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "rpm-import-key.service"

FILES_${PN} +=  " \
    ${base_libdir}/systemd \
"
