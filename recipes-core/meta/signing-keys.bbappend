# Copyright (C) 2017 Wind River

def import_gpg_key(d, path):
    import bb
    gpg_bin = d.getVar('GPG_BIN', True) or \
              bb.utils.which(os.getenv('PATH'), "gpg")
    cmd = '%s --import %s' % (gpg_bin, path)
    status, output = oe.utils.getstatusoutput(cmd)
    if status:
        raise bb.build.FuncFailed('Failed to import gpg key (%s): %s' %
                                  (path, output))

def check_gpg_key(d, keyid):
    import bb
    gpg_bin = d.getVar('GPG_BIN', True) or \
              bb.utils.which(os.getenv('PATH'), "gpg")
    cmd = '%s --list-keys -a "%s"' % (gpg_bin, keyid)
    status, output = oe.utils.getstatusoutput(cmd)
    if status:
        return False
    else:
        return True

python do_import_keys () {
    if d.getVar('RPM_SIGN_PACKAGES', True) == '1':
        # Check if the key is already imported
        if check_gpg_key(d, d.getVar("RPM_GPG_NAME", True)) is True:
            return

        if d.getVar("RPM_GPG_PRIVKEY", True):
            # Import private key of the rpm signing key
            import_gpg_key(d, d.getVar('RPM_GPG_PRIVKEY', True))
}

# sign_rpm depends on do_export_public_keys in oe-core,
# so keys have been already imported when running sign_rpm
addtask do_import_keys before do_export_public_keys
