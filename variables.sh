#!/usr/bin/env bash
# central variable file to source from other scripts

# domain data
export domain=
export subdomain=
export fqdn="$subdomain.$domain"
export host=$(hostname -s)

# smtp auth data
export smtphost=
export smtpport=
export smtpname=
export smtppassword=
export smtpfrom=

# nextcloud data
export user=
export nc_pw=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 16)
export base_dir=
export data_dir="$base_dir/data"
export nc_config_dir=/var/snap/nextcloud/current/nextcloud/config
export cred_file=/etc/credstore.encrypted/borgmatic.pw
export borg_repo=
export borg_pw=
export admin_addr=
