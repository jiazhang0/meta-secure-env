#
# Copyright (C) 2017 Wind River Systems, Inc.
#

PACKAGES =+ "${PN}-switch_root.static"

do_compile_append_class-target() {
    ${CC} ${CFLAGS} ${LDFLAGS} -static sys-utils/switch_root.o \
        -o ${B}/switch_root.static
}

do_install_append_class-target() {
    install -d ${D}/sbin
    install -m 0755 ${B}/switch_root.static ${D}/sbin/switch_root.static
}

FILES_${PN}-switch_root.static = "/sbin/switch_root.static"
