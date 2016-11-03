#
# Copyright (C) 2015-2016 Wind River Systems, Inc.
#

inherit user-key-store

python do_sign() {
    import re

    if ('${TARGET_ARCH}' != 'x86_64') and (not re.match('i.86', '${TARGET_ARCH}')):
        return

    if '${UEFI_SB}' != '1':
        return

    # Make sure the kernel image has been signed before kernel_do_deploy()
    # which prepares the kernel image for creating usb/iso.
    kernel = '${B}/arch/x86/boot/bzImage'

    # Prepare the unsigned kernel image for manual signing.
    import shutil
    shutil.copy(kernel, '${B}/bzImage.unsigned')

    sb_sign(kernel, kernel, d)

    shutil.copyfile(kernel, '${D}/boot/bzImage-${KERNEL_RELEASE}')
}
addtask sign after do_install before do_package do_populate_sysroot do_deploy

python do_sign_kernel_initramfs() {
    import re

    if ('${TARGET_ARCH}' != 'x86_64') and (not re.match('i.86', '${TARGET_ARCH}')):
        return

    if '${UEFI_SB}' != '1':
        return

    if ('${INITRAMFS_IMAGE}' == '') or ('${INITRAMFS_IMAGE_BUNDLE}' != '1'):
        return

    # Make sure the kernel image has been signed before kernel_do_deploy()
    # which prepares the kernel image for creating usb/iso.
    kernel_initramfs = '${B}/arch/x86/boot/bzImage.initramfs'

    # Prepare the unsigned kernel image for manual signing.
    import shutil
    shutil.copy(kernel_initramfs, '${B}/bzImage.initramfs.unsigned')

    sb_sign(kernel_initramfs, kernel_initramfs, d)

    shutil.copyfile(kernel_initramfs, '${D}/boot/bzImage-initramfs-${MACHINE}.bin')
}
addtask sign_kernel_initramfs after do_bundle_initramfs before do_deploy

do_deploy_append() {
    local dir="${DEPLOYDIR}/efi-unsigned"

    install -d $dir

    if [ -f "${B}/bzImage.unsigned" ]; then
        install -m 0600 "${B}/bzImage.unsigned" "$dir/bzImage"
    fi

    if [ -f "${B}/bzImage.initramfs.unsigned" ]; then
        install -m 0600 "${B}/bzImage.initramfs.unsigned" "$dir/bzImage.initramfs"
    fi
}
