FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append_class-target += " \
	${@bb.utils.contains('DISTRO_FEATURES', 'signed_rpm',  'file://Added-logic-to-check-the-autosigned-rpm-packages.patch',  '', d)} \
"
