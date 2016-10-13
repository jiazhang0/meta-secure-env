FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append_class-target += " \
	${@bb.utils.contains('DISTRO_FEATURES', 'signed_rpm',  'file://Create-tmp-flag-file-for-autosign-rpm-packages.patch',  '', d)} \
"
