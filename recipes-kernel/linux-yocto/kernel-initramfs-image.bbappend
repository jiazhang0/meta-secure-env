#
# Copyright (C) 2017 Wind River Systems, Inc.
#

inherit user-key-store

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
