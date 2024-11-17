#!/usr/bin/env bash

set -eEuo pipefail  # make bash reasonably strict

# set flag defaults
FROM=
LOG_FILE=

# set positional defaults
ERROR=
TO=

# define help message
usage() {
    local prog=$(basename "${0}")
    local indent_length="${#prog}"
    local indent=$(printf "%${indent_length}s")

    # ensure that lines with the prog or indent don't exceed 80 characters!
    cat << EOF
NAME
    $prog - Notify user in case of failed backup.

SYNOPSIS
    $prog [-h | --help] [-f | --from FROM] [-l | --log LOG_FILE]
    $indent ERROR TO

DESCRIPTION
                                                                               |
    This script is meant to be used with $(printf "\e]8;;https://torsion.org/borgmatic/\aBorgMatic\e]8;;\a"). If used in an $(printf "\e]8;;https://torsion.org/borgmatic/docs/how-to/monitor-your-backups/#error-hooks/\aerror hook\e]8;;\a"), it
    will send an email to a specified address when a scheduled backup fails.
    
    You have to pass the \`{error}' value, and the recipient. Optionally, you
    can pass the \`{log_file}' argument to the \`--log' flag, to attach the
    error log to the notification mail.

    A working \`mail' command is required.

OPTIONS

    Basic Options

        -h, --help     display this help message and exit

    Advanced Options

        -f, --from     sender address, e.g., "Backups <borg@example.org>"
        -l, --log      path to a logfile to attach

    Positional Arguments

        ERROR          the error message
        TO             recipient address, e.g., "Admin <admin@example.org>"

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
		        VERBOSE=true  # basically a NOOP
		        ;;
		    -q|--quiet)
		        VERBOSE=false
		        ;;
		    # Advanced Options
		    -f|--from)
		        shift
		    	    FROM="${1}"
		        ;;
		    -l|--log)
		        shift
		    	    LOG_FILE="${1}"
		    	    if [[ ! -f "$LOG_FILE" ]]; then
		    	        echo -e "Log file ${LOG_FILE} doesn't exist.\n"
		    	        exit 2
		    	    fi
		        ;;
		    -*)  # fail on unrecognized flags
		        echo -e "Unknown flag ${argument}\n"
		        usage
		        exit 2
		        ;;
		    *)  # parse positionals
		        if [[ -z $ERROR ]]; then
		            ERROR="${argument}"
		        elif [[ -z $TO ]]; then
		            TO="${argument}"
		        else
		            echo -e "Unknown positional argument ${argument}\n"
		            exit 2
		        fi
		        ;;
		esac
		shift
	done
	# check, whether log file is valid
	# check, whether required args where provided
	if [[ -z $ERROR ]]; then
		echo -e "Missing argument ERROR\n"
		usage
		exit 2
	elif [[ -z $TO ]]; then
		echo -e "Missing argument TO\n"
		usage
		exit 2
	fi
}

send_mail() {
	LOG_ARGS=()
	LOG_MSG=
    if [[ ! -z "$LOG_FILE" ]]; then
        LOG_ARGS=(-A "$LOG_FILE")
        LOG_MSG="See the attached log for details."
    fi

    cat <<- EOF | mail "${LOG_ARGS[@]}" $TO
		Subject: Failed Backup

		A scheduled backup has failed with the following error:
		$ERROR
		
		$LOG_MSG
	EOF
}

# only run this if executed as a script, not if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	get_opts "${@}"
	send_mail
	exit 0
fi
