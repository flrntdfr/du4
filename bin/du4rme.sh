#!/bin/bash
# Florent Dufour
# Oct. 2022
# Remove except

#set -ex

VERBOSE=false
DRY_RUN=false

usage() {
  echo -e "Remove all files, except the ones specified *in the current directory*.
  du4 rme [-h] [-n] [-v] files_to_keep"
}

# --------- #
# PARSE CLI #
# --------- #

while getopts 'vnh' opt; do
	case "$opt" in
		v)
			VERBOSE=true
			;;

		n)
			DRY_RUN=true
			;;

		h)
			usage
			exit 0
			;;

		?)
			echo "Invalid command option." >&2
      usage >&2
			exit 1
			;;
		esac
done
shift "$(($OPTIND -1))"

# ---- #
# MAIN #
# ---- #

main() {

  ignore=""
  #ignore="-not -name .."

  for f_ignore in "$@"; do
    f_ignore=${f_ignore%/} # Remove trailing slash if there is one (dirs)
    ignore=${ignore}"-not -name ${f_ignore} "
  done

  command="find . $ignore -maxdepth 1"

  if ! $DRY_RUN; then
    command=${command}" -exec rm -rf {} +"
  fi

  if ! $VERBOSE; then
    command=${command}" 2>&1 1>/dev/null"
  fi

  eval "$command"
}

# ------ #
# CHECKS #
# ------ #

if [ $# -eq 0 ]
  then
    usage >&2
    exit 1
fi

# ---- #
# EXEC #
# ---- #

main "$@"