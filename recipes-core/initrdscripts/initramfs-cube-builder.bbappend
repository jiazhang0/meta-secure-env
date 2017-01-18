FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "\
    file://init.cryptfs \
    file://init.ima \
"

do_install_append() {
    if [ x"${STORAGE_ENCRYPTION}" = x"1" ]; then
        install -m 0500 ${WORKDIR}/init.cryptfs ${D}
    fi

    if [ x"${IMA}" = x"1" ]; then
        install -m 0500 ${WORKDIR}/init.ima ${D}
    fi
}

FILES_${PN} += " \
    /init.cryptfs \
    /init.ima \
"

# Install the minimal stuffs only, and don't care how the external
# environment is configured.
# @bash: sh
# @coreutils: echo, mkdir, mknod, dirname, basename, cp, rm, sleep
#             seq, printf, cut
# @grep: grep
# @gawk: awk
# @kmod: modprobe, depmod
# @net-tools: ifconfig
# @trousers: tcsd
# @procps: pkill
# @util-linux: blkid, mount, umount
RDEPENDS_${PN} += "\
    bash \
    coreutils \
    grep \
    gawk \
    kmod \
    net-tools \
    procps \
    util-linux-blkid \
    util-linux-mount \
    util-linux-umount \
"

RRECOMMENDS_${PN} += "kernel-module-efivarfs"
