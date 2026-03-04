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


# Test and set existence, permission and ownership of a directory.
ensureDir() {
   local path="$1"

   if ! [ -d "$path" ]; then
      echo '*** Creating directory '"$path"'...'
      mkdir -- "$path"
   fi

   echo '*** Setting permissions on '"$path"'...'
   chown -- root:wheel "$path"
   chmod -- 755 "$path"
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
# echo PID to calling process
#
echo $$

#
# Setup log dir for usb service utilities log
#
LOGDIR=/Library/Logs/Omnissa\ Horizon\ Client
mkdir -p "$LOGDIR"

LOG=$LOGDIR/horizon-usb-init.log
rm -f "$LOG"
echo "Initializing USB Remote Desktop Services" >> "$LOG"

#
# Setup Horizon application support folder for USB use
#
SUPPORT_DIR='/Library/Application Support/Omnissa'
ensureDir "$SUPPORT_DIR"
ensureDir "$SUPPORT_DIR"'/Omnissa Horizon Client'


#
# Modify owner and perms of Library USB binaries.
#
LIBDIR=""
if [ "$#" -eq 1 ]; then
   if [ -d "$1" ]; then
      LIBDIR="$1"
      echo "Using the new pkg install mode" >> "$LOG"
   else
      THIS="`canonicalize_file "$0"`"
      LIBDIR="`dirname -- "$THIS"`"
      echo "Using the legacy dmg install mode" >> "$LOG"
   fi
fi

if [ ! -z "$LIBDIR" ]; then
   chown -R root:wheel "$LIBDIR/Open Horizon Client Services" \
                       "$LIBDIR/Horizon Client Services" \
                       "$LIBDIR/services.sh" \
                       "$LIBDIR/horizon-eucusbarbitrator"

   chmod 4755 "$LIBDIR/Open Horizon Client Services"

   chmod 755 "$LIBDIR/Horizon Client Services" \
             "$LIBDIR/services.sh" \
             "$LIBDIR/horizon-eucusbarbitrator"
   defaults -currentHost write /Library/Preferences/com.omnissa.horizon.client.mac \
            promptedUSBServicesInstall -bool YES
fi
