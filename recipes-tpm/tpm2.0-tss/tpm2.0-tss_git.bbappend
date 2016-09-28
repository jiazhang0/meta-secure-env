#
# Copyright (C) 2016 Wind River Systems, Inc.
#

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

inherit systemd

SRC_URI += "\
	file://tpm2.0-tss.service \
"

RRECOMMENDS_${PN} += "\
	kernel-module-tpm-crb \
	kernel-module-tpm-tis \
"

do_install_append () {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/tpm2.0-tss.service ${D}${systemd_unitdir}/system
}

SYSTEMD_PACKAGES = "resourcemgr"
SYSTEMD_SERVICE_resourcemgr = "tpm2.0-tss.service"
SYSTEMD_AUTO_ENABLE_resourcemgr = "enable"

FILES_resourcemgr += "${systemd_unitdir}/system/tpm2.0-tss.service"
