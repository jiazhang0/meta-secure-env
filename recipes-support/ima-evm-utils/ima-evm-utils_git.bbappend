#
# Copyright (C) 2016-2017 Wind River Systems, Inc.
#

PACKAGES =+ "${PN}-evmctl.static"

do_compile_append_class-target() {
    ${CC} ${CFLAGS} ${LDFLAGS} -static \
        -include config.h -L=${libdir} \
        -Wl,--start-group -lcrypto -lkeyutils -ldl \
        ${S}/src/evmctl.c ${S}/src/libimaevm.c \
        -Wl,--end-group -o ${B}/src/evmctl.static
}

do_install_append_class-target() {
    install -m 0700 ${B}/src/evmctl.static ${D}${sbindir}/evmctl.static
}

FILES_${PN}-evmctl.static = "${sbindir}/evmctl.static"
