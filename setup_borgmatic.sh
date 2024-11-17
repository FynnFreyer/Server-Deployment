#!/usr/bin/env bash

# make bash picky
set -euo pipefail

source variables.sh

# setup systemd service credentials
echo -n "$borg_pw" | systemd-creds encrypt - $cred_file

# install borgmatic and create config dir
apt-get install -y borgmatic
mkdir -p /etc/borgmatic

# install notify script for error hook
cp notify.sh /usr/local/bin/

# install exclude patterns
cp borgmatic/excludes /etc/borgmatic/excludes

# harden borgmatic
# backup systemd unit file
UNIT=/usr/lib/systemd/system/borgmatic.service
UNIT_BAK="${UNIT}.bak"
if [[ ! -f "$UNIT_BAK" ]]; then
	cp "$UNIT" "$UNIT_BAK"
fi

# restore default unit file
cp "$UNIT_BAK" "$UNIT"

# enable write only paths
sed -i "s/^ProtectSystem=full$/ProtectSystem=strict/" "$UNIT"
echo "ReadWritePaths=-$nc_config_dir" >> "$UNIT"  # necessary for toggling maintenance mode
echo "ReadOnlyPaths=-$data_dir" >> "$UNIT"
# pass config through bind mounts
echo "ProtectHome=tmpfs" >> "$UNIT"
echo "BindPaths=-${HOME}/.cache/borg -${HOME}/.config/borg -${HOME}/.borgmatic -${HOME}/.ssh" >> "$UNIT"

# render template files
for tmpl in borgmatic/*.tmpl; do
  file="${tmpl%.tmpl}"
  cat $tmpl | envsubst | sed -e 's/§/$/g' > $file
done

# install non-template files
for file in borgmatic/*; do
  if [[ ! "$file" =~ ".\.tmpl" ]]; then
    cp "$file" "/etc/$file"
  fi
done

# reload borgmatic
systemctl daemon-reload

