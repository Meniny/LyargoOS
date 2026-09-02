#!/bin/sh -x
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Apply LyargoOS branding overrides (hostname, user, passwords).
# Runs after adduser.sh (01) and display-manager-autologin.sh (02).

if [ -f ${NEWROOT}/etc/void-live.conf ]; then
    . ${NEWROOT}/etc/void-live.conf
fi

_user="${LIVE_USER:-live}"
_hostname="${LIVE_HOSTNAME:-lyargoos-live}"
_password="${LIVE_PASSWORD:-lyargoos}"

# Set hostname
echo "$_hostname" > ${NEWROOT}/etc/hostname

# If void-mklive created "anon" but we want a different user, rename it
if [ "$_user" != "anon" ] && [ -d ${NEWROOT}/home/anon ]; then
    chroot ${NEWROOT} usermod -l "$_user" -d "/home/$_user" -m anon
    if [ -f ${NEWROOT}/etc/sudoers.d/99-void-live ]; then
        sed -i "s/anon/$_user/g" ${NEWROOT}/etc/sudoers.d/99-void-live
    fi
    if [ -f ${NEWROOT}/etc/default/live.conf ]; then
        sed -i "s/USERNAME=anon/USERNAME=$_user/" ${NEWROOT}/etc/default/live.conf
    fi
    # Fix SDDM autologin to use the correct username
    if [ -f ${NEWROOT}/etc/sddm.conf ]; then
        sed -i "s/User=anon/User=$_user/" ${NEWROOT}/etc/sddm.conf
    fi
fi

# Set passwords
chroot ${NEWROOT} sh -c "echo 'root:${_password}' | chpasswd -c SHA512"
chroot ${NEWROOT} sh -c "echo '${_user}:${_password}' | chpasswd -c SHA512"

# Copy skel files to the live user's home directory
if [ -d ${NEWROOT}/etc/skel ] && [ -d "${NEWROOT}/home/$_user" ]; then
    cp -an ${NEWROOT}/etc/skel/. ${NEWROOT}/home/$_user/ 2>/dev/null
    chroot ${NEWROOT} chown -R $_user:$_user "/home/$_user"
fi
