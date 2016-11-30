FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "\
    file://tcsd.conf \
    file://tcsd.service \
    file://fix-deadlock-and-potential-hung.patch \
    file://fix-event-log-parsing-problem.patch \
    file://fix-incorrect-report-of-insufficient-buffer.patch \
    file://trousers-conditional-compile-DES-related-code.patch \
    file://Fix-segment-fault-if-client-hostname-cannot-be-retri.patch \
"

SYSTEMD_SERVICE_${PN} = "tcsd.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install_append () {
    install -m 0600 ${WORKDIR}/tcsd.conf ${D}${sysconfdir}
    chown tss:tss ${D}${sysconfdir}/tcsd.conf

    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/tcsd.service ${D}${systemd_unitdir}/system
}
