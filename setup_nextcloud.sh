#!/usr/bin/env bash

# make bash picky
set -euo pipefail

source variables.sh

# allow access to media and system monitoring
snap connect nextcloud:removable-media
snap connect nextcloud:network-observe

# configure resource usage
snap set nextcloud php.memory-limit=8G
snap set nextcloud nextcloud.cron-interval=1m
snap set nextcloud http.compression=true

# setup nextcloud

# setup
nextcloud.manual-install "$user" "$nc_pw"
echo Password: $nc_pw
read -p "Write down the password now! Press enter to continue afterwards"
# clear pw from screen
tput cuu 2
tput ed

# setup HTTPS
nextcloud.enable-https lets-encrypt

# substitute variables in template files
for tmpl in config/*.config.php.tmpl; do
  file="${tmpl%.tmpl}"
  cat $tmpl | envsubst | sed -e 's/§/$/g' > $file
done

# install config files
cp config/*.config.php $nc_config_dir/

# setup theming via occ

# customize signup page
nextcloud.occ theming:config name "Fynn's Cloud"
nextcloud.occ theming:config url https://cloud.fynns.site
nextcloud.occ theming:config imprintUrl https://fynns.site/impressum
nextcloud.occ theming:config privacyUrl https://fynns.site/privacy-policy
nextcloud.occ theming:config slogan "For convenience and collaboration"
# colors
nextcloud.occ theming:config color "#000000"
nextcloud.occ theming:config primary_color "#3584E4"
#nextcloud.occ theming:config background "#FFFFFF"
# logo and favicon
cp logo.png $base_dir/
nextcloud.occ theming:config logo $base_dir/logo.png
nextcloud.occ theming:config logoheader $base_dir/logo.png
nextcloud.occ theming:config favicon $base_dir/logo.png
# disable further changes
nextcloud.occ theming:config disable-user-theming yes
# enable custom css app and set css theme
nextcloud.occ app:enable theming_customcss
nextcloud.occ config:app:set theming_customcss customcss --value="$(awk '{printf "%s\\n", $0}' custom.css)"

# app settings

# disable useless apps
nextcloud.occ app:disable activities
nextcloud.occ app:disable dashboard
nextcloud.occ app:disable photos
nextcloud.occ app:disable circles
nextcloud.occ app:disable recommendations

# setup collabora
# install dependencies
apt install -y fontconfig glibc-source
# restart collabora apps
nextcloud.occ app:disable richdocumentscode
nextcloud.occ app:disable richdocuments
nextcloud.occ config:app:delete richdocuments public_wopi_url
nextcloud.occ config:app:delete richdocuments wopi_url
nextcloud.occ app:enable richdocuments
nextcloud.occ app:enable richdocumentscode

# install useful apps
nextcloud.occ app:enable deck  # kanban-style board
nextcloud.occ app:enable spreed  # video conferencing
nextcloud.occ app:enable drawio  # collaborative diagramming
nextcloud.occ app:enable polls  # self-hosted doodle alternative
nextcloud.occ app:enable forms  # self-hosted questionaires

nextcloud.occ app:enable groupfolders  # group-wide shared folders
nextcloud.occ app:enable group_default_quota  # set quotas based on group membership
nextcloud.occ app:enable quota_warning  # warn user before exhausting quotas
nextcloud.occ app:enable announcementcenter  # send notifications to all users

snap restart nextcloud

