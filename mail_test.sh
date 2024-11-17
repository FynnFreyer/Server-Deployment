#!/usr/bin/env bash

set -euo pipefail

src_name="Fynn Freyer"
dest_name="Auch Fynn Freyer"
dest_mail=fynn@fynns.site
cc_name="Immernoch Fynn Freyer"
cc_mail=fynn.freyer@googlemail.com

src_mail=${USER}@$(cat /etc/mailname)
dtime=$(date)

msg_file=email.msg

cat << EOF > $msg_file
Subject: Nullmailer test at $dtime
From: $src_name  <$src_mail>
To: $dest_name  <$dest_mail>
Cc: $cc_name <$cc_mail>

Sent at $dtime

$src_name was here
and now is gone
but left his name
to carry on.

This is a second paragraph thats kinda long, really really long, so long that I truly hope that it does the right thing and wraps.

Sincerely
$src_name

PS, @$cc_name: Hi!
EOF

cat $msg_file | nullmailer-inject -h
