#
# Copyright (C) 2017 Wind River Systems, Inc.
#

FILESPATH_append := ":${@base_set_filespath(['${THISDIR}'], d)}/${PN}"
SRC_URI += "file://0001-pm-verify-package-s-keyid-with-installed.patch \
           "

# import gpg pubkey to native rpm db.
# Actually target smartpm doesn't have to do this, but we can't assign the dependency to a native recipe only, like this:
# do_populate_sysroot[depends]_class-target += [foo:bar]
do_populate_sysroot[depends] += "signing-keys-native:do_import_rpm_key"
