#
# Copyright (C) 2017 Wind River Systems, Inc.
#

inherit user-key-store deploy

fakeroot python do_sign() {
    initramfs = None

    if '${INSTALL_INITRAMFS}' == '1':
        initramfs = '${D}/boot/${INITRAMFS_IMAGE}${INITRAMFS_EXT_NAME}.cpio.gz'
    elif '${INSTALL_BUNDLE}' == '1':
        initramfs = '${D}/boot/${KERNEL_IMAGETYPE}-initramfs${INITRAMFS_EXT_NAME}'

    if initramfs == None or not os.path.exists(initramfs):
        return

    uks_sel_sign(initramfs, d)
}
addtask sign after do_install before do_deploy do_package

do_deploy() {
    initramfs=""
    if [ x"${INSTALL_INITRAMFS}" = x"1" ]; then
        initramfs="${D}/boot/${INITRAMFS_IMAGE}${INITRAMFS_EXT_NAME}.cpio.gz"
    elif [ x"${INSTALL_BUNDLE}" = x"1" ]; then
        initramfs="${D}/boot/${KERNEL_IMAGETYPE}-initramfs${INITRAMFS_EXT_NAME}"
    fi

    if [ -n "$initramfs" -a -f "$initramfs.p7b" ]; then
        install -d "${DEPLOYDIR}"

        install -m 0600 "$initramfs.p7b" "${DEPLOYDIR}"
    fi
}
addtask deploy after do_install before do_build
