#!/usr/bin/env bash
#
# Common functions
unset ERROR #
declare -A ARGS

error() {
  echo -e "\e[31mERROR: $1\e[0m"
  ERROR=$2
}

errorAndExit() {
  echo -e "\e[31mERROR: $1\e[0m"
  exit $2
}

info() {
  echo -e "\e[34mINFO: ${1}\e[0m"
}

printCliArgs() {
  for each in "${!ARGS[@]}"
  do
    echo "ARGS[${each}]=${ARGS[${each}]}"
  done
}

processCliArgs() {
  #  Reads arguments into associative array ARGS[]
  #  Key-Value argument such as --myarg="argvalue" adds an element ARGS[--myarg]="argvalue"
  #
  #  USAGE: processCliArgs $*
  for each in $*; do
    if [[ "$(echo ${each} | grep '=' >/dev/null ; echo $?)" == "0" ]]; then
      key=$(echo ${each} | cut -d '=' -f 1)
      value=$(echo ${each} | cut -d '=' -f 2)
      if [[ "${ARGS[--debug]}" ]]; then
        shopt -s nocasematch # set shell option to match case insensitive. https://unix.stackexchange.com/questions/132480/case-insensitive-substring-search-in-a-shell-script
        if [[ "${key}" =~ "key" || "${key}" =~ "pass" ]]; then
          info "Processing Key-Value argument ${key}=${value:0:3}*********************"
        else
          info "Processing Key-Value argument ${key}=${value}"
        fi
        shopt -u nocasematch
      fi
      ARGS[${key}]="${value}"
    else
      errorAndExit "Argument must contain = character as in --key=value"
    fi
  done
}

warn() {
  echo -e "\e[33mWARNING: ${1}\e[0m"
}
