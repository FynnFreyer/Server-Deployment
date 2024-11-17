#!/usr/bin/env bash

set -euo pipefail

source variables.sh

# install and enable sendmail service
DEBIAN_FRONTEND=noninteractive apt-get install -y nullmailer mailutils

# set the mail name
echo "$fqdn" > /etc/mailname

# fill config templates and install files
for tmpl in nullmailer/*.tmpl; do
  file="${tmpl%.tmpl}"
  cat $tmpl | envsubst | sed -e 's/§/$/g' > /etc/$file
done

