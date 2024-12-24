#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin
if [ "$1" == "" ]; then
  exit 0
fi

if [ "$1" == "--import" ]; then
  # Since gpg2 is uses libcap, and $2 is 600, gpg is not able to open it, neither as root (due to libcap enforcement)
  # So we have to make it a+r
  gpg --homedir /root/.gnupg --list-keys &>/dev/null
  gpg --homedir /root/.gnupg --trust-model always --import <$2 2>&1 | grep -Ee "gpg: key " | cut -d ':' -f 2 | cut -d ' ' -f 3
  exit $?
fi

if [ "$1" == "--show-key" ]; then
  gpg --homedir /root/.gnupg --fingerprint --list-public-keys "$2"
  exit $?
fi

exit 0
