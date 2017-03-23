SUMMARY = "A tool used to create, persist, evict a passphrase \
for full-disk-encryption with TPM 2.0"
DESCRIPTION = " \
This project provides with an implementation for \
creating, persisting and evicting a passphrase with TPM 2.0. \
The passphrase and its associated primary key are automatically \
created by RNG engine in TPM. In order to avoid saving the \
context file, the created passphrase and primary key are always \
persistent in TPM. \
"
SECTION = "devel"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=35c0ab29d291dbbd14d66fd95521237f"

SRC_URI = " \
    git://github.com/WindRiver-OpenSourceLabs/cryptfs-tpm2.git \
"
SRCREV = "28adbea486ccfabc9d6d1f1e19554e5f33fb5d6f"
PV = "0.4.4+git${SRCPV}"

DEPENDS += "tpm2.0-tss"
RDEPENDS_${PN} += "libtss2 libtctisocket tpm2.0-tools"

PARALLEL_MAKE = ""

S = "${WORKDIR}/git"

EXTRA_OEMAKE = " \
    prefix="${prefix}" \
    sbindir="${sbindir}" \
    libdir="${libdir}" \
    includedir="${includedir}" \
    tpm2_tss_includedir="${STAGING_LIBDIR}" \
    tpm2_tss_libdir="${STAGING_INCDIR}" \
    CC="${CC}" \
    EXTRA_CFLAGS="${CFLAGS}" \
    EXTRA_LDFLAGS="${LDFLAGS}" \
"

do_install() {
    oe_runmake install DESTDIR="${D}"
}

FILES_${PN} = "\
    ${sbindir} \
    ${libdir} \
"
