# Copyright (C) 2017 Wind River

def import_gpg_key(d, keyfile, gpg_path):
    import bb
    gpg_bin = d.getVar('GPG_BIN', True) or \
              bb.utils.which(os.getenv('PATH'), "gpg2") or \
              bb.utils.which(os.getenv('PATH'), "gpg")

    cmd = '%s --homedir %s --import %s' % (gpg_bin, gpg_path, keyfile)

    status, output = oe.utils.getstatusoutput(cmd)
    if status:
        raise bb.build.FuncFailed('Failed to import gpg key (%s) with gpg path %s, fail reason: %s' % \
                                  (keyfile, gpg_path, output))

def check_gpg_key(d, keyid):
    import bb
    gpg_bin = d.getVar('GPG_BIN', True) or \
              bb.utils.which(os.getenv('PATH'), "gpg2") or \
              bb.utils.which(os.getenv('PATH'), "gpg")

    gpg_path = d.getVar('GPG_PATH', True)
    cmd = "%s --homedir %s --list-keys -a %s" % \
                   (gpg_bin, gpg_path, keyid)

    # create the GPG_PATH if it is not available
    if not os.path.exists(gpg_path):
        command = ' '.join(('mkdir -p', gpg_path))
        status, output = oe.utils.getstatusoutput(command)
        if status:
            raise bb.build.FuncFailed('Failed to create GPG_PATH: %s' % gpg_path)

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
            import_gpg_key(d, d.getVar('RPM_GPG_PRIVKEY', True), \
                           d.getVar('GPG_PATH', True))
}

# sign_rpm depends on do_export_public_keys in oe-core,
# so keys have been already imported when running sign_rpm
addtask do_import_keys before do_export_public_keys

do_import_keys[depends] += "gnupg-native:do_populate_sysroot"
