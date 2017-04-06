FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Backports from rpm-5_4 branch of CVS.
# Only backports related to pgp, key management, beecrypt and OpenSSL are 
# included.
EXTRA_OPENSSL_SRC_URI = " \
    file://0000-cipher-stub-in-cipher-methods-and-object.patch \
    file://0001-pgp-permit-non-repudiable-signature-on-all-crypto-st.patch \
    file://0009-ssl-tweak-config-options-run-in-FIPS-140-2-mode-best.patch \
    file://0011-ssl-rewrite-to-use-the-higher-level-EVP-layer-haul-t.patch \
    file://0012-rsa-fix-lookup-pubkey-before-finalizing-context-for-.patch \
    file://0013-pgp-configurable-non-repudiable-signature-pubkey-has.patch \
    file://0014-ssl-fix-use-ssl-pkey-pkey.dsa-not-ssl-dsa-for-pubkey.patch \
    file://0017-sanity.patch \
    file://0019-sanity.patch \
    file://0020-bc-add-non-repudiable-RSA-signatures.patch \
    file://0023-macros-add-additional-tested-signature-digest-algos.patch \
    file://0024-pgp-ensure-pubkey-algo-names-are-initialized.patch \
    file://0025-pgp-rework-DSA-SHA1-in-order-to-support-DSA2-signatu.patch \
    file://0026-asn1-swipe-a-standalone-copy-of-SEC_QuickDERDecodeIt.patch \
    file://0027-autoFu-fix-chk-libcrypto-not-libopenssl-for-symbol-M.patch \
    file://0028-ssl-fix-follow-openssl-hash-disabler-conventions-Mar.patch \
    file://0029-pgp-add-crypto-stack-identifier-use-with-base64-armo.patch \
    file://0030-pgp-unsigned-int-for-nbits-qbits-everywhere.patch \
    file://0031-pgp-set-pend-accurately-when-calling-pgpImplMpiItem.patch \
    file://0033-misc-expose-mpbzero.patch \
    file://0034-pgp-add-ECDSA-goop-correct-a-typo.patch \
    file://0035-hkp-stub-in-ECDSA-support.patch \
    file://0036-bc-do-PKCS1-in-binary-update-to-current-conventions.patch \
    file://0037-bc-mpi-names-following-BeeCrypt-conventions-haul-out.patch \
    file://0038-hkp-document-more-of-the-API.patch \
    file://0039-ecdsa-define-disabler-bits.patch \
    file://0041-jbj-refactor-some-table-lookup-helpers.patch \
    file://0042-ecdsa-define-RPMSIGTAG_ECDSA-RPMTAG_ECDSAHEADER.patch \
    file://0043-pgp-fix-rescusitate.patch \
    file://0044-ecdsa-implement-RPMSIGTAG_ECDSA-RPMTAG_ECDSAHEAER-us.patch \
    file://0045-jbj-ecdsa-generate-non-repudiable-ecdsa-signature-wh.patch \
    file://0046-typo.patch \
    file://0049-ssl-prefer-use-non-repudiable-ecdsa-signature.patch \
    file://0051-ssl-calculate-ecdsa-public-key-length-with-rounding.patch \
    file://0052-bc-stub-in-ECDSA-parameters-ensure-bit-counts-are-co.patch \
    file://0054-ssl-ensure-bit-counts-are-correct.patch \
    file://0060-coverity-1214094.patch \
    file://0061-coverity-1214095.patch \
    file://0062-coverity-1214080.patch \
    file://0063-coverity-124081.patch \
    file://0064-coverity-1214082.patch \
    file://0065-coverity-1214083.patch \
    file://0066-coverity-1214084.patch \
    file://0067-coverity-1214085.patch \
    file://0070-rpmdb-pkgio.c-typofix.patch \
    file://0071-fix-make-sure-the-rpmgi-ref-is-released-on-gpg-invoc.patch \
    file://rpm-limit-crypto.patch \
    file://rpm-fix-md5sum-checksum-cmp.patch \
    file://0074-fix-rpm-error-after-openssl-disabled-weak-cipher.patch \
    file://0075-ssl-fix-resurrect-rsa-sig.patch \
    file://0076-Create-tmp-flag-file-for-autosign-rpm-packages.patch \
    file://0077-Enable-configuration-for-gpg-digest-algorithm.patch \
"
SRC_URI_append = " ${@base_contains('PACKAGECONFIG', 'openssl', '${EXTRA_OPENSSL_SRC_URI}', '', d)}"

SRC_URI_append_openssl-fips = "\
	file://rpm-openssl-fips-crypto.patch \
	file://fipsld \
"

PACKAGECONFIG_append = " openssl"

# If FIPS is enabled, we also force openssl.
PACKAGECONFIG_append_class-target = " ${@['', 'openssl fips'][d.getVar('OPENSSL_FIPS_ENABLED', True) == '1']}"
PACKAGECONFIG[fips] = ",,openssl-fips,"

# When OpenSSL is selected, we use it as -the- crypto library
PACKAGECONFIG[openssl] = "--with-openssl --with-usecrypto=openssl,--without-openssl,openssl,"

OVERRIDES_prepend = "${@base_contains('PACKAGECONFIG', 'fips', 'openssl-fips:', '', d)}"

DEPENDS += "${@base_contains('PACKAGECONFIG', 'fips', 'openssl-fips', '', d)}"

export FIPS_SIG = "${STAGING_LIBDIR}/ssl/fips-2.0/bin/incore"
export FIPSLD_CC = "${HOST_PREFIX}gcc ${HOST_CC_ARCH}${TOOLCHAIN_OPTIONS}"
export FIPSLD_LIBCRYPTO = "${WORKDIR}/libcrypto.a"
export CC_openssl-fips = "${WORKDIR}/fipsld"

# IA32 doesn't support the incore script, so we MUST use qemu.
# qemu is very slow, so only do this for IA32.
#
# i586 will need the same patches, but they do not yet work properly.
#
QEMUDEP ??= ""
QEMUDEP_openssl-fips_x86-64 = "qemu-native"
DEPENDS += "${QEMUDEP}"

inherit qemu

# Based on the qemu_run_binary
def qemu_gen_runpath(data, rootfs_path):
    qemu_binary = qemu_target_binary(data)
    if qemu_binary == "qemu-allarch":
        qemu_binary = "qemuwrapper"

    libdir = rootfs_path + data.getVar("libdir", False)
    base_libdir = rootfs_path + data.getVar("base_libdir", False)

    return "PSEUDO_UNLOAD=1 " + qemu_binary + " -L " + rootfs_path \
            + " -E LD_LIBRARY_PATH=" + libdir + ":" + base_libdir

export FIPS_SIG_x86-64 = ""

FIPSLD-SED_x86-64 = """-e 's,SIG=`",SIG=`${@qemu_gen_runpath(d, d.getVar('STAGING_DIR_TARGET', True))}:$LIBPATHS ",'"""
### End ia32 workaround

### Regular version, non-IA32
FIPSLD-SED ?= ""

### Enable debugging
FIPSLD-SED_append = " -e 's,#set -x,set -x ; exec 1> fipsld.log 2>\&1,'"
do_configure_prepend_openssl-fips() {
	sed ${FIPSLD-SED} \
		-e 's,THERE=".*"..,THERE="${STAGING_LIBDIR}/ssl/fips-2.0",' \
		-i ${WORKDIR}/fipsld
	chmod 0755 ${WORKDIR}/fipsld
	# We need a local copy as it may be modified in place
	cp ${STAGING_BASELIBDIR}/libcrypto.a ${FIPSLD_LIBCRYPTO}
}

# Set the digest algorithm used for verifying file integrity
# If this value changes, and two different packages have different values
# the "same file" validation (two packages have a non-conflict file)
# will fail.  This may lead to upgrade problems.  You should treat this
# value as a distribution wide setting, and only change it when you intend
# a full system upgrade!
#
# Defined file digest algorithm values (note: not all are available!):
#       1       MD5 (legacy RPM default)
#       2       SHA1
#       3       RIPEMD-160
#       5       MD2
#       6       TIGER-192
#       8       SHA256
#       9       SHA384
#       10      SHA512
#       11      SHA224
#       104     MD4
#       105     RIPEMD-128
#       106     CRC-32
#       107     ADLER-32
#       108     CRC-64 (ECMA-182 polynomial, untested uint64_t problems)
#       109     Jenkins lookup3.c hashlittle()
#       111     RIPEMD-256
#       112     RIPEMD-320
#       188     BLAKE2B
#       189     BLAKE2BP
#       190     BLAKE2S
#       191     BLAKE2SP
RPM_FILE_DIGEST_ALGO ?= "1"

# Note: the following change to the non-repudiable signatures requires
# PACKAGECONFIG to include OpenSSL.
#
# All packages build with RPM5 contain a non-repudiable signature.
# The purpose of this signature is not to show authenticity of a package,
# but instead act as a secondary package wide validation that shows it
# wasn't damaged by accident in transport.  (When later you sign the package,
# this signature may or may not be replaced as there are two signature
# slots, one for DSA/RSA, and one reserved.)
#
# The following is the list of choices for the non-repudiable signature
# (note: not all of these are implemented):
#       DSA             (default)
#       RSA             (implies SHA1)
#       ECDSA           (implies SHA256)
#       DSA/SHA1
#       DSA/SHA224
#       DSA/SHA256
#       DSA/SHA384
#       DSA/SHA512
#       RSA/SHA1
#       RSA/SHA224
#       RSA/SHA256
#       RSA/SHA384
#       RSA/SHA512
#
# Note: ECDSA signatures are not supported in this version of RPM
RPM_SELF_SIGN_ALGO ?= "DSA"

# Algorithm for gpg digest during rpm siging
RPM_GPG_DIGEST_ALGO ?= "sha1"

do_install_append() {
	# Configure -distribution wide- package crypto settings
	# If these change, effectively all packages have to be upgraded!
	sed -i -e 's,%_build_file_digest_algo.*,%_build_file_digest_algo ${RPM_FILE_DIGEST_ALGO},' ${D}/${libdir}/rpm/macros.rpmbuild
	sed -i -e 's,%_build_sign.*,%_build_sign ${RPM_SELF_SIGN_ALGO},' ${D}/${libdir}/rpm/macros.rpmbuild
	sed -i -e 's,%_gpg_digest_algo.*,%_gpg_digest_algo ${RPM_GPG_DIGEST_ALGO},' ${D}/${libdir}/rpm/macros
}
