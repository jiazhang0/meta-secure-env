FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

inherit systemd

SRC_URI += " \
    file://rpm-key-import.service \
    file://rpm-key-import.sh \
"

do_install_append() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/rpm-key-import.service ${D}${systemd_unitdir}/system

    install -d ${D}${sbindir}
    install -m 0700 ${WORKDIR}/rpm-key-import.sh ${D}${sbindir}
}

SYSTEMD_PACKAGES += "${PN}"
SYSTEMD_SERVICE_${PN} += "rpm-key-import.service"

FILES_${PN} += " \
    ${sbindir}/rpm-key-import.sh \
"
