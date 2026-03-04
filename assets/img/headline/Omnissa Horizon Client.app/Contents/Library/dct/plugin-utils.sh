#!/bin/bash
#
# Copyright (c) 2020 Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Public
#
# This script implements util functions for plugin manager on Mac.
#


#----------------------------------------------------------------
#
# read_loglevel_from_env --
#
#    Read env variable via launchctl on Mac platform
#
#    Arguments:
#    Name of environment variable
#
#----------------------------------------------------------------

function read_loglevel_from_env()
{
   local var=$(trim $1)

   local loglevel=$(launchctl getenv "$var")

   echo $loglevel
}


#----------------------------------------------------------------
#
# set_env_var --
#
#    Set env variable via launchctl on Mac platform
#
#    Arguments:
#    1. name of environment variable
#    2. value of environment variable
#
#----------------------------------------------------------------

function set_env_var()
{
   local var=$1
   local loglevel=$2

   unset_env_var "$var"
   if [ -n "$loglevel" ]; then
      launchctl setenv "$var" "$loglevel"
   fi
}


#----------------------------------------------------------------
#
# unset_env_var --
#
#    Unset environment variable via launchctl on Mac platform
#
#    Arguments:
#    Name of environment variable
#
#----------------------------------------------------------------

function unset_env_var()
{
   local var=$1

   launchctl unsetenv "$var"
}


#----------------------------------------------------------------
#
# read_loglevel_from_defaults --
#
#    read loglevel from user's defaults on Mac platform
#
#    Arguments:
#    1. name of domain
#    2. name of key
#
#----------------------------------------------------------------

function read_loglevel_from_defaults()
{
   local domain=$(trim $1)
   local key=$(trim $2)
   local loglevel=""

   defaults read "$domain" "$key" &> /dev/null
   if [ $? -ne 1 ]; then
      loglevel=$(defaults read "$domain" "$key")
   fi

   echo $loglevel
}


#----------------------------------------------------------------
#
# write_user_defaults --
#
#    Write user's defaults via defaults command on Mac platform
#
#    Arguments:
#    1. name of domain
#    2. key name for domain
#    3. value name for domain
#
#----------------------------------------------------------------

function write_user_defaults()
{
   local domain=$(trim $1)
   local key=$(trim $2)
   local loglevel=$(trim $3)

   delete_user_defaults "$domain" "$key"
   if [ -n "$loglevel" ]; then
      defaults write "$domain" "$key" "$loglevel"
   fi
}


#----------------------------------------------------------------
#
# delete_user_defaults --
#
#    delete user's defaults via defaults command on Mac platform
#
#    Arguments:
#    1. name of domain
#    2. name of key
#
#----------------------------------------------------------------

function delete_user_defaults()
{
   local domain=$(trim $1)
   local key=$(trim $2)

   defaults delete "$domain" "$key" &> /dev/null
}


#----------------------------------------------------------------
#
# format_date_string --
#
#    Format date string to epoch timestamp on Mac platform
#
#    Arguments:
#    Date string
#
#----------------------------------------------------------------

function format_date_string()
{
   local date="$1"
   local timestamp=$(date -j -f '%b %d %T' "$date" +%s 2> /dev/null)

   echo $timestamp
}


#----------------------------------------------------------------
#
# read_file_modified_time --
#
#    Read time when file data last modified on Mac platform
#
#    Arguments:
#    Name of file
#
#----------------------------------------------------------------

function read_file_modified_time()
{
   local file="$1"
   local file_time=$(stat -f %m "$file")

   echo $file_time
}


#----------------------------------------------------------------
#
# check_installation_status --
#
#    Check installation status for a given plugin feature
#
#----------------------------------------------------------------

function check_installation_status()
{
  # For Mac client, feature installation is not optional, do nothing here
  :
}


#----------------------------------------------------------------
#
# update_shell_context --
#
#    update shell context to make the log level change on
#    environment variable take effect in current shell.
#
#----------------------------------------------------------------

function update_shell_context()
{
  # On Mac client, env variable is set by launchctl, no need to update
  # shell context to make the env taking effect, so nothing to do here.
  :
}
