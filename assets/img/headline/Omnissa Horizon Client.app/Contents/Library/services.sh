#!/bin/bash -p

# This executable runs with root privileges, so hardcode a PATH where
# unprivileged users cannot write.
export PATH=/bin:/sbin:/usr/bin:/usr/sbin


# Print a variable, even if its value is -n (unlike echo).
print_var() {
   printf -- %s "$1"
}


# Canonicalize the path of an existing directory.
canonicalize_dir() {
   # Bash's cd builtin can write to stdout.
   (cd -- "$1" >/dev/null && pwd -P)
}


# Canonicalize the path of an existing file.
canonicalize_file() {
   local file="$1"

   while [ -h "$file" ]; do
      file="`readlink -- "$file"`"
   done

   local dir="`dirname -- "$file"`"
   # 'dir' is a directory, or a symlink to a directory. Canonicalize it.
   print_var "`canonicalize_dir "$dir"`"/"`basename -- "$file"`"
}


# Test the ownership of a path
has_ownership() {
   local path="$1"
   local uid="$2"
   local gid="$3"

   # Numeric IDs are used because some systems have two names (or more)
   # associated with one number.
   set -- `ls -alnd -- "$path" 2>/dev/null`
   [ "$3" = "$uid" -a "$4" = "$gid" ]
}


if [ "$UID" -ne "$EUID" ]; then
   # We have been invoked by a set-UID process (case #1 above). Re-invoke
   # ourselves as sudo would have done it (case #2 above), i.e.:
   # o With the SUDO_UID environment variable set to the current UID.
   # o With the UID and EUID set to the current EUID.
   # This way the rest of this executable behaves consistently, regardless of
   # how the executable was invoked.

   export -- SUDO_UID="$UID"
   # To debug, it is very convenient to:
   # o Append -x to the line at the top of this file.
   # o Append >>/tmp/debug 2>&1 to the line below this comment.
   exec -- perl -XUe '$< = $>; exec(@ARGV)' -- "$0" "$@"
fi

#
# Setup runtime temp dir for log
#
LOGDIR=/Library/Logs/Omnissa\ Horizon\ Client
mkdir -p "$LOGDIR"

LOG=$LOGDIR/horizon-usb-service.log
rm -f "$LOG"

THIS="`canonicalize_file "$0"`"
THISDIR="`dirname -- "$THIS"`"
cd "$THISDIR"

if [ "$1" = "--force" ] ; then
   shift 1
else
   # Aim to test whether InitUsbServices.tool is exexuted
   if [ `stat -f "%u" ./horizon-eucusbarbitrator` -ne "0" ] ; then
      echo "USB services not yet initialized." >> "$LOG"
      exit 2
   fi
fi

#
# Main
#

case "$1" in
--start)
   echo "Starting USB Remote Desktop Services" >> "$LOG"

   #
   # Attempt to launch the usb arbitrator
   #
   ./horizon-eucusbarbitrator

   date >> "$LOG"
   echo "USB arbitrator started." >> "$LOG"

   date >> "$LOG"
   echo "USB daemon started." >> "$LOG"
   ;;

--stop)
   echo "Stopping USB Remote Desktop Services" >> "$LOG"
   ./horizon-eucusbarbitrator -k
   ;;

*)
   echo "Usage: $0 {--start|--stop}"
   exit 1
esac

exit 0
