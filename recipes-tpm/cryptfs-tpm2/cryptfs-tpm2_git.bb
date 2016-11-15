SUMMARY = "This project provides with an implementation \
for storing/restoring a passphrase with TPM 2.0"
DESCRIPTION = " \
This project provides with an implementation for \
storing/restoring a passphrase with TPM 2.0. The passphrase \
and its associated primary key are automatically created by \
RNG engine in TPM. In order to avoid saving the context file, \
the created passphrase and primary key are always persistent \
in TPM. \
"
SECTION = "devel"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=af9aa760caa1532b4f5c9874d4e8c753"

SRC_URI = " \
    git://github.com/WindRiver-OpenSourceLabs/cryptfs-tpm2.git \
"
SRCREV = "cc40708796019c9bee28e0fe119f6409d5aa1215"
PV = "0.2.1+git${SRCPV}"

DEPENDS += "tpm2.0-tss"
RDEPENDS_${PN} += "libtss2 libtctisocket"

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