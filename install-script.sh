#!/usr/bin/env bash

set -eEuo pipefail  # make bash reasonably strict

# IFS=$'\n\t'

# get the directory of this script, as per https://stackoverflow.com/a/246128
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# set defaults
VERBOSE=false
DEVICE=
USER="root"
PASSWORD=
KEY_FILE=

# define help message
usage() {
    local prog=$(basename "${0}")
    local indent_length="${#prog}"
    local indent=$(printf "%${indent_length}s")

    # ensure that lines with the prog or indent don't exceed 80 characters!
    cat << EOF
NAME
    $prog - Install NixOS to a disk.

SYNOPSIS
    $prog [-h | --help] [-v | --verbose] DEVICE

DESCRIPTION

    This script installs NixOS as described in the $(printf "\e]8;;https://nixos.org/manual/nixos/stable/#sec-installation\amanual\e]8;;\a").

    THIS WILL DELETE EVERYTHING ON THE SPECIFIED DISK, USE WITH CARE!

OPTIONS

    Basic Options

        -h, --help     display this help message and exit
        -v, --verbose  print more output

    Advanced Options

        -u, --user     username for admin, defaults to root
        -k, --key      install SSH-keys from file

    Positional Arguments

        DEVICE         the disk to install to, e.g., /dev/sdb

EOF
}

# parse arguments
get_opts() {
    while [[ $# -gt 0 ]]; do
        local argument="${1}"
        case "${argument}" in
            # Basic Options
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            # Advanced Options
            -u|--user)
                shift  # flag takes an argument
            	USER="${1}"
            	;;
            -p|--passwd|--password)
                shift  # flag takes an argument
            	PASSWORD="${1}"
            	;;
            -k|--key)
                shift  # flag takes an argument
            	KEY_FILE="${1}"
            	;;
            -*)  # fail on unrecognized flags
                echo -e "Unknown flag ${argument}\n"
                usage
                exit 2
                ;;
            *)  # parse positionals
                if [[ -z $DEVICE ]]; then
                    DEVICE="${argument}"
                else
                    echo -e "Unknown positional argument ${argument}\n"
                    exit 3
                fi
                ;;
        esac
        shift
    done
    # check, whether required args where provided
    if [[ -z $DEVICE ]]; then
        cat << EOF
Missing argument DEVICE.
Available devices:

$(lsblk -p)
EOF
        usage
        exit 4
    fi
}

log() {
    $VERBOSE && echo $1
}

configure_user() {
    local key=$(cat $KEY_FILE)
    local pass=$PASSWORD
    if [[ -z $pass ]]; then
        pass=$(cat /dev/random | tr -cd '[:print:]' | tr -d '\n' | head -c 16)
        echo "PASSWORD=${pass}"
    fi

    # write config
    cat > /mnt/etc/nixos/access.nix << EOF
{ ... }:
{
  users.users.${USER} = {
    isNormalUser = true;
    extraGroups = ["wheel" ];
    password = "$pass";
    openssh.authorizedKeys.keys = [ "$key" ];
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
}
EOF

    # import access config
    awk -v '/^\s*\]/ && !ins { print "    access.nix"; ins=1 } { print }' /mnt/etc/nixos/configuration.nix
}

install() {
    # $VERBOSE && echo "This does a thing verbosely." \
    #          || echo "This does a thing quietly." 1> /dev/null 2>&1

    # partition the device
    log "Partitioning $DEVICE."
    parted "$DEVICE" -- mklabel gpt
    parted "$DEVICE" -- mkpart root ext4 1GB 100%
    parted "$DEVICE" -- mkpart ESP fat32 1MB 1GB
    parted "$DEVICE" -- set 2 esp on

    # create a file system
    log "Creating file system."
    mkfs.ext4 -L root "${DEVICE}1"
    mkfs.fat -F 32 -n boot "${DEVICE}2"

    # mount the file system
    log "Mounting file system."
    mount /dev/disk/by-label/root /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot

    # generate config and install
    log "Creating OS config."
    nixos-generate-config --root /mnt

    if [[ USER != "root" ]]; then
        log "Generating user config"
        configure_user
    fi

    log "Installing the configured system."
    nixos-install
}

main() {
    log "Installing NixOS to ${DEVICE}."
    install
}

# only run this if executed as a script, not if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	get_opts "${@}"
	main
	exit 0
fi
