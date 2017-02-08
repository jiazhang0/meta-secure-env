#
# Copyright (C) 2017 Wind River Systems, Inc.
#

inherit package

PACKAGEFUNCS =+ "package_ima_hook"

# In order to re-sign the updated files during RPM installation,
# the new security.ima needs to be written immediately.
python package_ima_hook() {
    packages = d.getVar('PACKAGES', True)
    pkgdest = d.getVar('PKGDEST', True)

    pkg_blacklist = ('dbg', 'dev', 'doc', 'locale', 'staticdev')

    bb.note("Writing IMA hooks in RPM for %s ..." % d.getVar('PN', True))

    for pkg in packages.split():
        if (pkg.split('-')[-1] in pkg_blacklist) is True:
            continue

        pkgdestpkg = os.path.join(pkgdest, pkg)
        # pkgfiles is global in this context.
        files = ' '.join([os.sep + os.path.relpath(_, pkgdestpkg) for _ in pkgfiles[pkg]])

        # During RPM update, it is impossible to update evmctl and dependent
        # shared libraries while using evmctl to sign themselves.
        evmctl_bin = 'evmctl'
        if pkg == 'ima-evm-utils':
            evmctl_bin = evmctl_bin + '.static'

        postinst = r'''#!/bin/sh

# IMA post_install hook
if [ -z "$D" ]; then
    if [ -f /etc/keys/evm_privkey.pem -a -x /usr/sbin/''' + evmctl_bin + r''' ]; then
        files="''' + files + r'''"

        for f in $files; do
            # IMA appraisal is only applied to the regular file
            [ ! -f $f ] && continue

            /usr/sbin/''' + evmctl_bin + r''' ima_sign --rsa "$f"
        done
    fi
fi

'''
        postinst = postinst + (d.getVar('pkg_postinst_%s' % pkg, True) or '')
        d.setVar('pkg_postinst_%s' % pkg, postinst)
}
