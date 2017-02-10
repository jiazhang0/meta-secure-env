PACKAGES =+ "${PN}-setfattr.static"

do_compile_append_class-target() {
    ${CC} ${CFLAGS} ${LDFLAGS} -static \
        -I${S}/include -L=${libdir} \
        -DVERSION=\"${PV}\" -DPACKAGE=\"${PN}\" -DLOCALEDIR=\"${localedir}\" \
        -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 \
        -Wl,--start-group ${S}/setfattr/setfattr.c \
        ${B}/libattr/.libs/libattr.a ${B}/libmisc/.libs/libmisc.a \
        -Wl,--end-group -o ${B}/setfattr/setfattr.static
}

do_install_append_class-target() {
    install -m 0755 ${B}/setfattr/setfattr.static \
        ${D}${bindir}/setfattr.static
}

FILES_${PN}-setfattr.static += "${bindir}/setfattr.static"
