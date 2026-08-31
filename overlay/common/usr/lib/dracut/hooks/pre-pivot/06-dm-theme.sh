#!/bin/sh -x
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Apply DM theme for the live session.
# Runs after display-manager-autologin.sh (02) which overwrites /etc/sddm.conf.

# SDDM: set Breeze theme (default for KDE flavor)
if [ -x ${NEWROOT}/usr/bin/sddm ]; then
    cat >> ${NEWROOT}/etc/sddm.conf <<_EOF

[Theme]
Current=breeze
CursorTheme=breeze_cursors
_EOF
fi
