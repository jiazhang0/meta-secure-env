#
# Copyright (C) 2017 Wind River Systems, Inc.
#

inherit keys

def rpm_keys_dir(d):
    # we check the key files and create it if it is not available
    # if SIGNING_MODE = "user"
    check_user_keys(d, 'RPM')
    set_keys_dir('RPM', d)
    return uks_rpm_keys_dir(d)
