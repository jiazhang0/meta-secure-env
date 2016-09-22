#
# Copyright (C) 2015-2016 Wind River Systems, Inc.
#

SUMMARY = "shim is a trivial EFI application."
DESCRIPTION = "shim is a trivial EFI application that, when run, attempts to open and \
execute another application. It will initially attempt to do this via the \
standard EFI LoadImage() and StartImage() calls. If these fail (because secure \
boot is enabled and the binary is not signed with an appropriate key, for \
instance) it will then validate the binary against a built-in certificate. If \
this succeeds and if the binary or signing key are not blacklisted then shim \
will relocate and execute the binary."
HOMEPAGE = "https://github.com/rhinstaller/shim.git"
SECTION = "bootloaders"

LICENSE = "shim"
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=b92e63892681ee4e8d27e7a7e87ef2bc"
PR = "r0"
SRC_URI = " \
        git://github.com/rhinstaller/shim.git \
        file://shim-allow-to-verify-sha1-digest-for-Authenticode.patch \
        file://Update-verification_method-if-the-loaded-image-is-si.patch  \
        file://Skip-the-error-message-when-creating-MokListRT-if-ve.patch \
        file://Allow-to-override-the-path-to-openssl.patch \
        file://Fix-for-the-cross-compilation.patch \
        file://Fix-signing-failure-due-to-not-finding-certificate.patch \
        file://Prevent-from-removing-intermediate-.efi.patch \
        file://shim-fix-the-handling-EFI_SECURITY_VIOLATION.patch \
        file://Use-sbsign-to-sign-MokManager-and-fallback.patch \
        file://Fix-the-world-build-failure-due-to-the-missing-rule-.patch \
        file://Don-t-enforce-to-use-gnu89-standard.patch \
"
SRCREV = "6c180c6004ac464d7e83c1dc4c24047fad281b32"
PV = "0.9+git${SRCPV}"

COMPATIBLE_HOST = '(i.86|x86_64).*-linux'

inherit deploy user-key-store

S = "${WORKDIR}/git"
DEPENDS_append = "\
    gnu-efi nss openssl util-linux-native openssl-native nss-native \
    sbsigntool-native \
"

EFI_ARCH_x86 = "ia32"
EFI_ARCH_x86-64 = "x64"

EXTRA_OEMAKE = " \
	CROSS_COMPILE="${TARGET_PREFIX}" \
	LIB_GCC="`${CC} -print-libgcc-file-name`" \
	LIB_PATH="${STAGING_LIBDIR}" \
	EFI_PATH="${STAGING_LIBDIR}" \
	EFI_INCLUDE="${STAGING_INCDIR}/efi" \
	RELEASE="_${DISTRO}_${DISTRO_VERSION}" \
	DEFAULT_LOADER=\\\\\\grub${EFI_ARCH}.efi \
	OPENSSL=${STAGING_BINDIR_NATIVE}/openssl \
	HEXDUMP=${STAGING_BINDIR_NATIVE}/hexdump \
	PK12UTIL=${STAGING_BINDIR_NATIVE}/pk12util \
	CERTUTIL=${STAGING_BINDIR_NATIVE}/certutil \
	SBSIGN=${STAGING_BINDIR_NATIVE}/sbsign \
	AR=${AR} \
"

python () {
    if d.getVar('MOK_SB', True) == "1":
        d.appendVar('EXTRA_OEMAKE', ' VENDOR_CERT_FILE="${WORKDIR}/vendor_cert.cer"')

    if d.getVar('USE_USER_KEY', True) == "1":
        d.appendVar('EXTRA_OEMAKE', ' VENDOR_DBX_FILE="${WORKDIR}/vendor_dbx.esl"')
}

PARALLEL_MAKE = ""

EFI_TARGET = "/boot/efi/EFI/BOOT"
FILES_${PN} += "${EFI_TARGET}"

# Prepare the signing certificate and keys
python do_prepare_signing_keys() {
    if '${MOK_SB}' != '1':
        return

    # Prepare vendor_dbx.
    create_mok_vendor_dbx(d)

    import shutil

    # Prepare shim_cert and vendor_cert.
    dir = mok_sb_keys_dir(d)
    shutil.copyfile(dir + 'shim_cert.pem', '${S}/shim.crt')
    shutil.copyfile(dir + 'shim_cert.key', '${S}/shim.key')
    pem2der(dir + 'vendor_cert.pem', '${WORKDIR}/vendor_cert.cer', d)

    import bb.process

    # PKCS12 formatted private key with empty exporting cipher, and just used
    # by pesign. Same fuction as shim_cert.
    cmd = (' '.join(('${STAGING_BINDIR_NATIVE}/openssl', 'pkcs12',
           '-in', dir + 'shim_cert.pem',
           '-inkey', dir + 'shim_cert.key',
           '-export', '-passout', 'pass:""',
           '-out', '${S}/shim.p12')))
    try:
        result, _ = bb.process.run(cmd)
    except:
        raise bb.build.FuncFailed('ERROR: Unable to create shim.p12')
}
addtask prepare_signing_keys after do_configure before do_compile

python do_sign() {
    uefi_sb_sign('${S}/shim${EFI_ARCH}.efi', '${B}/shim${EFI_ARCH}.efi.signed', d)
}
addtask sign after do_compile before do_install

do_install() {
    install -d ${D}${EFI_TARGET}
    install -m 0600 ${B}/mm${EFI_ARCH}.efi.signed ${D}${EFI_TARGET}/mm${EFI_ARCH}.efi

    local dst="${D}${EFI_TARGET}/boot${EFI_ARCH}.efi"
    if [ x"${UEFI_SB}" = x"1" ]; then
        install -m 0600 ${B}/shim${EFI_ARCH}.efi.signed $dst
    else
        install -m 0600 ${B}/shim${EFI_ARCH}.efi $dst
    fi
}

# Install the unsigned images for manual signing
do_deploy() {
    install -d ${DEPLOYDIR}/efi-unsigned

    install -m 0600 ${B}/shim${EFI_ARCH}.efi ${DEPLOYDIR}/efi-unsigned/boot${EFI_ARCH}.efi
    install -m 0600 ${B}/mm${EFI_ARCH}.efi ${DEPLOYDIR}/efi-unsigned/mm${EFI_ARCH}.efi
}
addtask deploy after do_install before do_build
