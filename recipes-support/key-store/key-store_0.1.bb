#
# Copyright (C) 2017 Wind River Systems, Inc.
#

DESCRIPTION = "User key store for key installation"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit user-key-store

PACKAGES =+ " \
             ${PN}-ima-pubkey \
             ${PN}-ima-privkey \
            "

KEY_DIR = "/etc/keys"

# For IMA appraise
IMA_PRIV_KEY = "${KEY_DIR}/privkey_evm.pem"
IMA_PUB_KEY = "${KEY_DIR}/pubkey_evm.pem"

FILES_${PN}-ima-pubkey = "${IMA_PUB_KEY}"
CONFFILES_${PN}-ima-pubkey = "${IMA_PUB_KEY}"
FILES_${PN}-ima-privkey = "${IMA_PRIV_KEY}"
CONFFILES_${PN}-ima-privkey = "${IMA_PRIV_KEY}"

do_install() {
    src_dir="${@uks_ima_keys_dir(d)}"

    install -d "${D}${KEY_DIR}"
    install -m 644 "$src_dir/ima_pubkey.pem" "${D}${IMA_PUB_KEY}"
    install -m 400 "$src_dir/ima_privkey.pem" "${D}${IMA_PRIV_KEY}"
}
