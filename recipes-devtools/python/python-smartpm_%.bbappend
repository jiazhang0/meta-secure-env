#
# Copyright (C) 2017 Wind River Systems, Inc.
#

FILESPATH_append := ":${@base_set_filespath(['${THISDIR}'], d)}/${PN}"
SRC_URI += "file://0001-pm-verify-package-s-keyid-with-installed.patch \
           "
