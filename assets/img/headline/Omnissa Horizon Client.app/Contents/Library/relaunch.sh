#!/bin/bash

# Dev note: Do not move/rename this file during minor updates as
# it's needed for autoupdate and we ASSERT if it's not found.
# It will be OK to move/rename during major upgrades when users
# cannot autoupdate between versions.

if [ $# -ne 2 ]; then
  echo "Usage: $0 <pid> <app-path>"
  echo "Waits for process with <pid> to exit, then launches <app-path>"
  exit 1
fi

while [ `ps -p "$1" | grep "$1" | wc -l` -gt 0 ]; do
   sleep 5
done
open "$2"

