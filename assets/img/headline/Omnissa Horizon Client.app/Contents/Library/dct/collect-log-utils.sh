#!/bin/bash
#
# Copyright (c) 2020 Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Public
#
# Utils of log collection for Mac Client.
#

# Define global variables for log collection on Mac Client
COMPANY_NAME="Omnissa"
PRODUCT_NAME="$COMPANY_NAME Horizon Client"

client_log_dir=""
client_log_glob="horizon-client-[0-9]*.log"
DEFAULT_DIR="$HOME/Desktop/"
DEFAULT_TARGET="horizon-client-logs-`date +%Y-%m-%d_%I.%M.%S_%p_%Z`.zip"
LOG_PACKAGE_SUFFIX=".zip"
username_mac=""

# Path aliases
USER_PREFS_DIR=""
USER_LOG_DIR=""
OMNISSA_LOG_DIR=""
CLIENT_UI_DIR=""
PCOIP_LOG_DIR=""


#----------------------------------------------------------------
#
# getMacUserName --
#
#    Get user name on Mac based on user name in Bash shell
#
#    Arguments:
#    User name in Bash shell
#
#----------------------------------------------------------------

function getMacUserName()
{
   local user="$1"
   local mac_user

   if [ $user = "root" ]; then
      mac_user="administrator"
   else
      mac_user=$user
   fi

   echo $mac_user
}


#----------------------------------------------------------------
#
# check_directory --
#
#    Check if the directory to collect data exists
#
#----------------------------------------------------------------

function check_directory()
{
   username_mac=$(getMacUserName "$username")

   USER_PREFS_DIR="/Users/$username_mac/Library/Preferences"

   USER_LOG_DIR="/Users/$username_mac/Library/Logs"
   OMNISSA_LOG_DIR="$USER_LOG_DIR/$COMPANY_NAME"
   CLIENT_UI_DIR="$USER_LOG_DIR/$PRODUCT_NAME"
   PCOIP_LOG_DIR="$USER_LOG_DIR/$PRODUCT_NAME/teradici-$username_mac"

   client_log_dir="$CLIENT_UI_DIR"
   local dirs=("$OMNISSA_LOG_DIR")

   # Find the directory that logs are stored.
   for dir in "${dirs[@]}"; do
      if [ ! -d "$dir" ]; then
         throw_exception "The log directory "$dir" does not exist."
      fi
   done
}


#----------------------------------------------------------------
#
# package_dir --
#
#    Package directory to a zip
#
#    Arguments:
#    1. name fo zip
#    2. directory to be packaged
#
#----------------------------------------------------------------

function package_dir()
{
   local package=$1
   local dir=$2

   zip -r9 "$package" "$dir" &> /dev/null
   return $?
}


#----------------------------------------------------------------
#
# collect_data_all --
#
#    Legacy function: Collect all logs/dumps for Mac Client
#
#----------------------------------------------------------------

function collect_data_all()
{
   COLLECTED_FILES=(
      /Library/Logs/Omnissa/*
      /Library/Logs/Omnissa/Deem/*
      /Library/Logs/"$PRODUCT_NAME"/*
      /Library/Logs/Horizon\ Client*   # this gets Horizon Client Services.log
      "$OMNISSA_LOG_DIR"/*
      "$CLIENT_UI_DIR"/*
      "$CLIENT_UI_DIR"/proxy-app/*
      "$PCOIP_LOG_DIR"/*
      "$USER_LOG_DIR"/DiagnosticReports/horizon-*
      "$USER_PREFS_DIR"/"$PRODUCT_NAME"/*
      /Library/Application\ Support/Omnissa/usbarb.rules
   )

   # Uncomment to check which files get collected via COLLECTED_FILES
   # tar cf - ${COLLECTED_FILES[@]} | tar tvf -

   # Use -p to preserve file times
   cp -fp ${COLLECTED_FILES[@]} "$tmpdir/$targetDirectory" &> /dev/null

   # Collect data by plugin feature/components
   for file in ${PLUGIN_LIST[@]}; do
      collect_data_by_plugin_config "$file" "$dctLogTimeFilter"
   done
}


#----------------------------------------------------------------
#
# get_dct_log_dir --
#
#    Get the directory to store log file for DCT script.
#
#----------------------------------------------------------------

function get_dct_log_dir()
{
   local log_dir
   local user=$(get_current_user)

   user=$(getMacUserName "$user")
   log_dir="/Users/$user/Library/Logs/$COMPANY_NAME"

   echo $log_dir
}
