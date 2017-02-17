#
# Copyright (C) 2017 Wind River Systems, Inc.
#

DESCRIPTION = "Key store for key installation"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit user-key-store

S = "${WORKDIR}"

ALLOW_EMPTY_${PN} = "1"

PACKAGES =+ " \
             ${PN}-rpm-pubkey \
             ${PN}-ima-pubkey \
            "

# For RPM verification
RPM_KEY_DIR = "${sysconfdir}/pki/rpm-gpg"
FILES_${PN}-rpm-pubkey = "${RPM_KEY_DIR}/RPM-GPG-KEY-*"
CONFFILES_${PN}-rpm-pubkey = "${RPM_KEY_DIR}/RPM-GPG-KEY-*"

# Note IMA private key is not available if user key signing model used.
PACKAGES_DYNAMIC += "${PN}-ima-privkey"

KEY_DIR = "${sysconfdir}/keys"

# For IMA appraisal
IMA_PRIV_KEY = "${KEY_DIR}/privkey_evm.pem"
IMA_PUB_KEY = "${KEY_DIR}/pubkey_evm.pem"

FILES_${PN}-ima-pubkey = "${IMA_PUB_KEY}"
CONFFILES_${PN}-ima-pubkey = "${IMA_PUB_KEY}"

python () {
    if uks_signing_model(d) != "sample":
        return

    pn = d.getVar('PN', True) + '-ima-privkey'
    # Ensure the private key file can be included in key-store-ima-privkey
    d.setVar('PACKAGES_prepend', pn + ' ')
    d.setVar('FILES_' + pn, d.getVar('IMA_PRIV_KEY', True))
    d.setVar('CONFFILES_' + pn, d.getVar('IMA_PRIV_KEY', True))
}

do_install() {
    install -d "${D}${RPM_KEY_DIR}"

    for f in `ls ${WORKDIR}/RPM-GPG-KEY-*`; do
        [ ! -f "$f" ] && continue

        install -m 0400 "${WORKDIR}/$f" "${D}${RPM_KEY_DIR}"
    done

    src_dir="${@uks_ima_keys_dir(d)}"

    install -d "${D}${KEY_DIR}"
    install -m 644 "$src_dir/ima_pubkey.pem" "${D}${IMA_PUB_KEY}"

    if [ "${@uks_signing_model(d)}" = "sample" ]; then
        install -m 400 "$src_dir/ima_privkey.pem" "${D}${IMA_PRIV_KEY}"
    fi
}

pkg_postinst_${PN}-rpm-pubkey() {
    [ -n "$D" ] && return

    keydir="${RPM_KEY_DIR}"

    [ ! -d "$keydir" ] && mkdir -p "$keydir"

    # XXX: only import the new key
    for f in `ls $keydir/RPM-GPG-KEY-*`; do
        keyfile="$keydir/$f"

        [ ! -f "$keyfile" ] && continue

        ! rpm --import "$keyfile" && {
            echo "Unable to import the public key $f"
            exit 1
        }
    done
}
