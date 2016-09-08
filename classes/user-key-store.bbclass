#
# Copyright (C) 2016 Wind River Systems, Inc.
#

DEPENDS_append_class-target = " sbsigntool-native"
USER_KEY_SHOW_VERBOSE = "1"

def vprint(str, d):
    if d.getVar('USER_KEY_SHOW_VERBOSE', True) == '1':
        print(str)

def sign_efi_image(key, cert, input, output, d):
    import bb.process

    cmd = (' '.join((d.getVar('STAGING_BINDIR_NATIVE', True) + '/sbsign',
                     '--key', key, '--cert', cert,
                     '--output', output, input)))
    vprint("Signing %s with the key %s ..." % (input, key), d)
    try:
        result, _ = bb.process.run(cmd)
    except:
        raise bb.build.FuncFailed('ERROR: Unable to sign %s' % input)

def uefi_sb_keys_dir(d):
    set_keys_dir('UEFI', d)
    return d.getVar('UEFI_KEYS_DIR', True) + '/'

def check_uefi_user_keys(d):
    dir = uefi_sb_keys_dir(d)

    for _ in ('PK', 'KEK', 'DB'):
        if not os.path.exists(dir + _ + '.key'):
            vprint("%s.key is unavailable" % _, d)
            return False

        if not os.path.exists(dir + _ + '.pem'):
            vprint("%s.pem is unavailable" % _, d)
            return False

def uefi_sb_sign(input, output, d):
    if d.getVar('UEFI_SB', True) != '1':
        return

    _ = uefi_sb_keys_dir(d)
    sign_efi_image(_ + 'DB.key', _ + 'DB.pem', input, output, d)

def mok_sb_keys_dir(d):
    if d.getVar('MOK_SB', True) != '1':
        return

    set_keys_dir('MOK', d)
    return d.getVar('MOK_KEYS_DIR', True) + '/'

def sb_sign(input, output, d):
    if d.getVar('MOK_SB', True) == '1':
        mok_sb_sign(input, output, d)
    elif d.getVar('UEFI_SB', True) == '1':
        uefi_sb_sign(input, output, d)

def check_mok_user_keys(d):
    dir = mok_sb_keys_dir(d)

    for _ in ('shim_cert', 'vendor_cert'):
        if not os.path.exists(dir + _ + '.key'):
            vprint("%s.key is unavailable" % _, d)
            return False

        if not os.path.exists(dir + _ + '.pem'):
            vprint("%s.pem is unavailable" % _, d)
            return False

def mok_sb_sign(input, output, d):
    if d.getVar('MOK_SB', True) == '1':
        _ = mok_sb_keys_dir(d)
        sign_efi_image(_ + 'shim_cert.key', _ + 'shim_cert.pem', input, output, d)

# Convert the PEM to DER format.
def pem2der(input, output, d):
    import bb.process

    cmd = (' '.join((d.getVar('STAGING_BINDIR_NATIVE', True) + '/openssl',
           'x509', '-inform', 'PEM', '-outform', 'DER', 
           '-in', input, '-out', output)))
    try:
        result, _ = bb.process.run(cmd)
    except:
        raise bb.build.FuncFailed('ERROR: Unable to convert %s to %s' % (input, output))

# Convert the certificate (PEM formatted) to ESL.
__pem2esl() {
    "${STAGING_BINDIR_NATIVE}/cert-to-efi-sig-list" \
        -g ${UEFI_SIG_OWNER_GUID} "$1" "$2"
}

# Blacklist the sample DB, shim_cert, vendor_cert by default.
__create_default_mok_sb_blacklist() {
    __pem2esl "${SAMPLE_MOK_KEYS_DIR}/shim_cert.pem" \
        "${TMPDIR}/sample_shim_cert.esl"

    __pem2esl "${SAMPLE_MOK_KEYS_DIR}/vendor_cert.pem" \
        "${TMPDIR}/sample_vendor_cert.esl"

    # Cascade the sample DB, shim_cert and vendor_cert to
    # the default vendor_dbx.
    cat "${TMPDIR}/sample_shim_cert.esl" \
        "${TMPDIR}/sample_vendor_cert.esl" >> "${TMPDIR}/blacklist.esl"
}

__create_default_uefi_sb_blacklist() {
    __pem2esl "${SAMPLE_UEFI_KEYS_DIR}/DB.pem" \
        "${TMPDIR}/sample_DB.esl"

    cat "${TMPDIR}/sample_DB.esl" > "${TMPDIR}/blacklist.esl"
}

# Cascade the default blacklist and user specified blacklist if any.
def __create_blacklist(d):
    tmp_dir = d.getVar('TMPDIR', True)

    vprint('Preparing to create the default blacklist %s' % tmp_dir + '/blacklist.esl', d)

    bb.build.exec_func('__create_default_uefi_sb_blacklist', d)
    if d.getVar('MOK_SB', True) == '1':
        bb.build.exec_func('__create_default_mok_sb_blacklist', d) 

    def __pem2esl_dir (dir):
        if not os.path.isdir(dir):
            return

        dst = open(tmp_dir + '/blacklist.esl', 'wb+')

        for _ in os.listdir(dir):
            fn = os.path.join(dir, _)
            if not os.path.isfile(fn):
                continue

            cmd = (' '.join((d.getVar('STAGING_BINDIR_NATIVE', True) + '/cert-to-efi-sig-list',
                   '-g', d.getVar('UEFI_SIG_OWNER_GUID', True), fn,
                   tmp_dir + '/' + _ + '.esl')))
            try:
                result, _ = bb.process.run(cmd)
            except:
                vprint('Unable to convert %s' % fn)
                continue

            with open(fn) as src:
                shutil.copyfileobj(src, dst)
                src.close()

        dst.close()

    # Cascade the user specified blacklists.
    __pem2esl_dir(uefi_sb_keys_dir(d) + 'DBX')

    if d.getVar('MOK_SB', True) == '1':
        __pem2esl_dir(mok_sb_keys_dir(d) + 'vendor_dbx')

# To ensure a image signed by the sample key cannot be loaded by a image
# signed by the user key, e.g, preventing the shim signed by the user key
# from loading the grub signed by the sample key, certain sample keys are
# added to the blacklist.
def create_mok_vendor_dbx(d):
    if d.getVar('MOK_SB', True) != '1' or d.getVar('USE_USER_KEY', True) != '1':
        return

    __create_blacklist(d)

    import shutil
    shutil.copyfile(d.getVar('TMPDIR', True) + '/blacklist.esl', \
                    d.getVar('WORKDIR', True) + '/vendor_dbx.esl')

def create_uefi_dbx(d):
    if d.getVar('UEFI_SB', True) != '1' or d.getVar('USE_USER_KEY', True) != '1':
        return

    __create_blacklist(d)

    import shutil
    shutil.copyfile(d.getVar('TMPDIR', True) + '/blacklist.esl', \
                    d.getVar('S', True) + '/DBX.esl')

create_uefi_user_keys() { 
    local deploy_dir="${DEPLOY_DIR_IMAGE}/user-keys/uefi_sb_keys"

    install -d "$deploy_dir"

    # PK is self-signed.
    "${STAGING_BINDIR_NATIVE}/openssl" req -new -x509 -newkey rsa:2048 \
        -sha256 -nodes -days 3650 \
        -subj "/CN=PK Certificate for $USER@`hostname`/" \
        -keyout "$deploy_dir/PK.key" \
        -out "$deploy_dir/PK.pem"

    # KEK is signed by PK. 
    "${STAGING_BINDIR_NATIVE}/openssl" req -new -newkey rsa:2048 \
        -sha256 -nodes \
        -subj "/CN=KEK Certificate for $USER@`hostname`" \
        -keyout "$deploy_dir/KEK.key" \
        -out "${TMPDIR}/KEK.csr"

    "${STAGING_BINDIR_NATIVE}/openssl" x509 -req -in "${TMPDIR}/KEK.csr" \
        -CA "$deploy_dir/PK.pem" -CAkey "$deploy_dir/PK.key" \
        -set_serial 1 -days 3650 -out "$deploy_dir/KEK.pem"

    # DB is signed by KEK.
    "${STAGING_BINDIR_NATIVE}/openssl" req -new -newkey rsa:2048 \
        -sha256 -nodes \
        -subj "/CN=DB Certificate for $USER@`hostname`" \
        -keyout "$deploy_dir/DB.key" \ 
        -out "${TMPDIR}/DB.csr"

    "${STAGING_BINDIR_NATIVE}/openssl" x509 -req -in "${TMPDIR}/DB.csr" \
        -CA "$deploy_dir/KEK.pem" -CAkey "$deploy_dir/KEK.key" \
        -set_serial 1 -days 3650 -out "$deploy_dir/DB.pem"
}

create_mok_user_keys() {
    local deploy_dir="${DEPLOY_DIR_IMAGE}/user-keys/mok_sb_keys"

    install -d "$deploy_dir"

    "${STAGING_BINDIR_NATIVE}/openssl" req -new -x509 -newkey rsa:2048 \
        -sha256 -nodes -days 3650 -subj "/CN=Shim Certificate for $USER@`hostname`/" \
        -keyout "$deploy_dir/shim_cert.key" -out "$deploy_dir/shim_cert.pem"

    "${STAGING_BINDIR_NATIVE}/openssl" req -new -x509 -newkey rsa:2048 \
        -sha256 -nodes -days 3650 -subj "/CN=Vendor Certificate for $USER@`hostname`/" \
        -keyout "$deploy_dir/vendor_cert.key" -out "$deploy_dir/vendor_cert.pem" \
}

def create_user_keys(sb, d):
    vprint('Creating the user keys for %s Secure Boot ...' % sb, d)
    bb.build.exec_func('create_' + sb.lower() + '_user_keys', d)

def sanity_check_user_keys(sb, may_exit, d):
    vprint('Checking the user keys for %s Secure Boot ...' % sb, d)

    if sb == 'UEFI':
        _ = check_uefi_user_keys(d)
    else:
        _ = check_mok_user_keys(d)

    if _ == False:
        if may_exit:
            raise bb.build.FuncFailed('ERROR: Unable to find %s user key ...' % sb)

        vprint('Failed to check the user keys for %s Secure Boot ...' % sb, d)
    else:
        vprint('Found the user keys for %s Secure Boot ...' % sb, d)

    return _

# MOK|UEFI_KEYS_DIR need to be updated whenever reading them.
def set_keys_dir(sb, d):
    if (d.getVar(sb + '_SB', True) != "1") or (d.getVar('USE_USER_KEY', True) != "1"):
        return

    if d.getVar(sb + '_KEYS_DIR', True) == d.getVar('SAMPLE_' + sb + '_KEYS_DIR', True):
        d.setVar(sb + '_KEYS_DIR', d.getVar('DEPLOY_DIR_IMAGE', True) + '/user-keys/' + sb.lower() + '_sb_keys')

# Check and/or generate the user keys
python do_check_user_keys_class-target () {
    vprint('Status before do_check_user_keys():', d)
    vprint('  MOK_SB: ${MOK_SB}', d)
    vprint('  UEFI_SB: ${UEFI_SB}', d)
    vprint('  USE_USER_KEY: ${USE_USER_KEY}', d)
    vprint('  MOK_KEYS_DIR: ${MOK_KEYS_DIR}', d)
    vprint('  UEFI_KEYS_DIR: ${UEFI_KEYS_DIR}', d)
    vprint('  SAMPLE_MOK_KEYS_DIR: ${SAMPLE_MOK_KEYS_DIR}', d)
    vprint('  SAMPLE_UEFI_KEYS_DIR: ${SAMPLE_UEFI_KEYS_DIR}', d)

    for _ in ('UEFI', 'MOK'):
        # Intend to use user key?
        if (d.getVar(_ + '_SB', True) != "1") or ("${USE_USER_KEY}" != "1"):
            continue

        # Check if the generation for user key is required. If so,
        # place the generated user keys to export/images/user-keys/.
        if d.getVar(_ + '_KEYS_DIR', True) == d.getVar('SAMPLE_' + _ + '_KEYS_DIR', True):
            d.setVar(_ + '_KEYS_DIR', '${DEPLOY_DIR_IMAGE}' + '/user-keys/' + _.lower() + '_sb_keys')

            if sanity_check_user_keys(_, False, d) == False:
                create_user_keys(_, d)
        else:
            # Raise error if not specifying the location of the
            # user keys for mok/uefi secure boot.
            sanity_check_user_keys(_, True, d)

    vprint('Results after do_check_user_keys():', d)
    vprint('  MOK_KEYS_DIR: %s' % d.getVar('MOK_KEYS_DIR', True), d)
    vprint('  UEFI_KEYS_DIR: %s' % d.getVar('UEFI_KEYS_DIR', True), d)
}

python do_check_user_keys () {
}

addtask check_user_keys before do_configure after do_patch
do_check_user_keys[lockfiles] = "${TMPDIR}/check_user_keys.lock"

# DEPENDS doesn't take effect for the tasks *BEFORE* do_configure,
# but we really need it in do_check_user_keys() which is called
# prior to do_configure().
do_check_user_keys[depends] += "\
    openssl-native:do_populate_sysroot \
    efitools-native:do_populate_sysroot \
"
