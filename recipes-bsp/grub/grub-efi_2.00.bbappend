#
# Copyright (C) 2016 Wind River Systems, Inc.
#

FILESEXTRAPATHS_prepend := "${THISDIR}/grub-efi:"

SRC_URI += " \
    file://0001-pe32.h-add-header-structures-for-TE-and-DOS-executab.patch \
    file://0002-shim-add-needed-data-structures.patch \
    file://0003-efi-chainloader-implement-an-UEFI-Exit-service-for-s.patch \
    file://0004-efi-chainloader-port-shim-to-grub.patch \
    file://0005-efi-chainloader-use-shim-to-load-and-verify-an-image.patch \
    file://0006-efi-chainloader-boot-the-image-using-shim.patch \
    file://0007-efi-chainloader-take-care-of-unload-undershim.patch \
    file://chainloader-handle-the-unauthenticated-image-by-shim.patch \
    file://chainloader-Don-t-check-empty-section-in-file-like-..patch \
    file://chainloader-Actually-find-the-relocations-correctly-.patch \
    file://Fix-32-bit-build-failures.patch \
    file://grub.cfg \
"

GRUB_BUILDIN_append = " chain"

# For efi_call_foo and efi_shim_exit
CFLAGS_append = " -fno-toplevel-reorder"

# Set a default root specifier.
inherit user-key-store

python __anonymous () {
    if d.getVar('MOK_SB', True) != "1":
        return

    # Override the default filename if mok-secure-boot enabled.
    # grub-efi must be renamed as grub${arch}.efi for working with shim.
    import re

    target = d.getVar('TARGET_ARCH', True)
    if target == "x86_64":
        grubimage = "grubx64.efi"
    elif re.match('i.86', target):
        grubimage = "grubia32.efi"
    else:
        raise bb.parse.SkipPackage("grub-efi is incompatible with target %s" % target)

    d.setVar("GRUB_IMAGE", grubimage)
}

do_install_append_class-target() {
    local cfg="${WORKDIR}/grub.cfg"

    # If uefi|mok-secure-boot is enabled, the linux command used to load kernel
    # image must be replaced by the chainloader command to guarantee the kernel
    # loading is authenticated. In addition, the initrd command becomes not
    # working if the linux command is not used. In this case, the initramfs image
    # will be always bundled into kernel image if initramfs is used.
    if [ x"${UEFI_SB}" = x"1" ]; then
        sed -i 's/^\s*linux /    chainloader /g' $cfg
        sed -i '/^\s*initrd /d' $cfg
    fi

    # Create a boot entry for Automatic Key Provision. This is required because
    # certain hardware, e.g, Intel NUC5i3MYHE, doedn't support to display a
    # customized BIOS boot option used to launch LockDown.efi.
    [ x"${UEFI_SB}" = x"1" ] && ! grep -q "Automatic Key Provision" $cfg &&
        cat >> $cfg <<_EOF

menuentry 'Automatic Key Provision' {
    chainloader /EFI/BOOT/LockDown.efi
 }
_EOF

    install -d ${D}${EFI_BOOT_PATH}
    install -m 0600 $cfg "${D}${EFI_BOOT_PATH}/grub.cfg"
}

python do_sign_class-target() {
    _ = '${D}${EFI_BOOT_PATH}/${GRUB_IMAGE}'
    sb_sign(_, _, d)
}

python do_sign() {
}
addtask sign after do_install before do_deploy do_package

do_deploy_append_class-target() {
    install -d ${DEPLOYDIR}/efi-unsigned

    install -m 0600 ${B}/${GRUB_IMAGE} ${DEPLOYDIR}/efi-unsigned
    cp -af ${D}${EFI_BOOT_PATH}/${GRUB_TARGET}-efi ${DEPLOYDIR}/efi-unsigned
}
