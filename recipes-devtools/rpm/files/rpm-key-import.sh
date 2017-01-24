#!/bin/sh

keydir="/etc/pki/rpm-gpg"

[ ! -d "$keydir" ] && exit 0

for f in `ls $keydir/RPM-GPG-KEY-*`; do
    keyfile="$keydir/$f"

    [ ! -f "$keyfile" ] && continue

    ! rpm --import "$keyfile" &&
        echo "Unable to import RPM key $keyfile" && exit 1
done

exit 0
