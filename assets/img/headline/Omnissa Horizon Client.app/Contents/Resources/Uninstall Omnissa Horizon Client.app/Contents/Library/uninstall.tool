#!/bin/bash -p

###
# Uninstall script for Horizon Client
# Copyright (c) Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Restricted
###

# This executable runs with root privileges, so hardcode a PATH where
# unprivileged users cannot write.
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Check running user
if (( $EUID != 0 )); then
    echo "Please run as root."
    exit
fi

echo "Welcome to Omnissa Horizon Client Uninstaller"

HELPER=com.omnissa.horizon.CDSHelper
HELPERPLIST=/Library/LaunchDaemons/$HELPER.plist
HELPERTOOL=/Library/PrivilegedHelperTools/$HELPER
if [ -f "$HELPERPLIST" ]; then
   echo "Stopping the helper tool: $HELPER"
   set -e
   /bin/launchctl bootout system "$HELPERPLIST"
   /bin/rm "$HELPERPLIST" || true
   /bin/rm "$HELPERTOOL" || true
fi

#forget from pkgutil
pkgutil --forget "com.omnissa.horizon.client.mac" > /dev/null 2>&1

# Remove Omnissa Horizon Client bundle
[ -e "/Applications/Omnissa Horizon Client.app" ] && /bin/rm -rf "/Applications/Omnissa Horizon Client.app"

# Remove Omnissa Deem
[ -e "/Library/Application Support/WorkspaceONE/EndpointTelemetryService/ws1etlm/uninstall.sh" ] && /bin/bash -p "/Library/Application Support/WorkspaceONE/EndpointTelemetryService/ws1etlm/uninstall.sh"  "HorizonClient"

echo "Omnissa Horizon Client uninstall process finished"

exit 0