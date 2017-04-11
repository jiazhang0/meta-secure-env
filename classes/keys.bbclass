#
# Copyright (C) 2017 Wind River Systems, Inc.
#

KEY_SHOW_VERBOSE = "1"

RPM = '${@bb.utils.contains("DISTRO_FEATURES", "rpm-signing", "1", "0", d)}'

def vprint(str, d):
    if d.getVar('KEY_SHOW_VERBOSE', True) == '1':
        print(str)

def uks_signing_model(d):
    return d.getVar('SIGNING_MODEL', True)

def uks_rpm_keys_dir(d):
    return d.getVar('RPM_KEYS_DIR', True) + '/'

def check_rpm_user_keys(d):
    dir = uks_rpm_keys_dir(d)

    if not os.path.exists(dir + 'RPM-GPG-PRIVKEY-' + d.getVar('RPM_GPG_NAME', True)):
        vprint("user rpm private key is unavailable", d)
        return False

create_rpm_user_keys() {
    local deploy_dir="${DEPLOY_DIR_IMAGE}/user-keys/rpm_keys"
    user_gpg_name="${RPM_GPG_NAME}"
    user_privkey_file="$deploy_dir/RPM-GPG-PRIVKEY-${user_gpg_name}"
    user_pubkey_file="$deploy_dir/RPM-GPG-KEY-${user_gpg_name}"

    install -d "$deploy_dir"
    tmpdir=`mktemp -d`

cat >$tmpdir/foo <<EOF
%echo Generating a standard key
Key-Type: RSA
Key-Length: 1024
Subkey-Type: ELG-E
Subkey-Length: 1024
Name-Real: ${user_gpg_name}
Name-Comment: with empty passphrase
Name-Email: ${user_gpg_name}@foo.com
Expire-Date: 0
%secring ${user_privkey_file}
%pubring ${user_pubkey_file}
# Do a commit here, so that we can later print "done" :-)
%commit
%echo done
EOF

   ${STAGING_BINDIR_NATIVE}/gpg --homedir $tmpdir --batch --gen-key $tmpdir/foo

   rm -rf $tmpdir
}

def create_user_keys(name, d):
    vprint('Creating the user keys for %s ...' % name, d)
    bb.build.exec_func('create_' + name.lower() + '_user_keys', d)

def sanity_check_user_keys(name, may_exit, d):
    vprint('Checking the user keys for %s ...' % name, d)

    if name == 'RPM':
        _ = check_rpm_user_keys(d)
    else:
        _ = False
        may_exit = True

    if _ == False:
        if may_exit:
            raise bb.build.FuncFailed('ERROR: Unable to find user key for %s ...' % name)

        vprint('Failed to check the user keys for %s ...' % name, d)
    else:
        vprint('Found the user keys for %s ...' % name, d)

    return _

# *_KEYS_DIR need to be updated whenever reading them.
def set_keys_dir(name, d):
    if (d.getVar(name, True) != "1") or (d.getVar('SIGNING_MODEL', True) != "user"):
        return

    if d.getVar(name + '_KEYS_DIR', True) == d.getVar('SAMPLE_' + name + '_KEYS_DIR', True):
        d.setVar(name + '_KEYS_DIR', d.getVar('DEPLOY_DIR_IMAGE', True) + '/user-keys/' + name.lower() + '_keys')

def check_user_keys(d, key_type):
    # we support checking the following keys
    if not key_type in ('UEFI_SB', 'MOK_SB', 'IMA', 'RPM'):
        return

    # Intend to use user key?
    if (d.getVar(key_type, True) != "1") or (d.getVar('SIGNING_MODEL', True) != "user"):
        return

    # Check if the generation for user key is required. If so,
    # place the generated user keys to export/images/user-keys/.
    if d.getVar(key_type + '_KEYS_DIR', True) == d.getVar('SAMPLE_' + key_type + '_KEYS_DIR', True):
        d.setVar(key_type + '_KEYS_DIR', '${DEPLOY_DIR_IMAGE}' + '/user-keys/' + key_type.lower() + '_keys')

        if sanity_check_user_keys(key_type, False, d) == False:
            create_user_keys(key_type, d)
        else:
            # Raise error if not specifying the location of the
            # user keys.
            sanity_check_user_keys(key_type, True, d)
