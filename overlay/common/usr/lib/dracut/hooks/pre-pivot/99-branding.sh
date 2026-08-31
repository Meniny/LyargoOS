#!/bin/sh -x
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Apply LyargoOS branding overrides (hostname, passwords).
# Runs after adduser.sh (01) so our values take precedence.

if [ -f ${NEWROOT}/etc/void-live.conf ]; then
    . ${NEWROOT}/etc/void-live.conf
fi

if [ -n "$LIVE_HOSTNAME" ]; then
    echo "$LIVE_HOSTNAME" > ${NEWROOT}/etc/hostname
fi

if [ -n "$LIVE_PASSWORD" ]; then
    _user="${LIVE_USER:-live}"
    chroot ${NEWROOT} sh -c "echo "root:${LIVE_PASSWORD}" | chpasswd -c SHA512"
    chroot ${NEWROOT} sh -c "echo "${_user}:${LIVE_PASSWORD}" | chpasswd -c SHA512"
fi
