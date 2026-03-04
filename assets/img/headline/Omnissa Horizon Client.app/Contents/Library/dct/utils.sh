#!/bin/bash
#
# Copyright (c) 2020 Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Public
#
# This script implements utility functions for DCT.
#

#----------------------------------------------------------------
#
# throw_exception --
#
#    Throw exception
#
#----------------------------------------------------------------

function throw_exception()
{
   print_error "$@"
   exit 1
}


#----------------------------------------------------------------
#
# print_error --
#
#    Print error message
#
#----------------------------------------------------------------

function print_error()
{
   echo "${0##*/}: $@" 1>&2
}


#----------------------------------------------------------------
#
# log_debug --
#
#    Print message to DCT log file
#
#----------------------------------------------------------------

log_debug()
{
   local timestamp=`date +"%Y-%m-%d %T%z"`
   echo "[$timestamp] $@" >> $dct_log_file
}


#----------------------------------------------------------------
#
# log_info --
#
#    Print message to standard output and DCT log file
#
#----------------------------------------------------------------

log_info()
{
   echo "$@"
   log_debug "$@"
}


#----------------------------------------------------------------
#
# log_error --
#
#    Print message to standard error output and DCT log file
#
#----------------------------------------------------------------

log_error()
{
   echo "$@" 1>&2
   log_debug "$@"
}


#----------------------------------------------------------------
#
# tolower --
#
#    Convert a string to lower case
#
#----------------------------------------------------------------

function tolower()
{
   local string=$1
   string=`echo "$string" | tr '[:upper:]' '[:lower:]'`
   echo $string
}


#----------------------------------------------------------------
#
# toupper --
#
#    Convert a string to upper case
#
#----------------------------------------------------------------

function toupper()
{
   local string=$1
   string=`echo "$string" | tr '[:lower:]' '[:upper:]'`
   echo $string
}


#----------------------------------------------------------------
#
# trim --
#
#    trim the head and tail " for a string
#
#----------------------------------------------------------------

function trim()
{
   local str=$1
   str="${str%\"}"
   str="${str#\"}"
   echo $str
}


#----------------------------------------------------------------
#
# intersect --
#
#    Get intersection of two list
#    (Items of source and target list are seperated by ',')
#
#----------------------------------------------------------------

function intersect()
{
   local source=$1
   local target=$2
   local source_list
   local target_list
   local result=""

   IFS=',' read -ra source_list <<< "$source"
   IFS=',' read -ra target_list <<< "$target"

   for source_item in ${source_list[@]}; do
      local found=0
      for target_item in ${target_list[@]}
      do
         if [ "$source_item" == "$target_item" ]; then
            found=1
            break;
         fi
      done

      if [ $found -eq 1 ]; then
         result+="$source_item,"
      fi
   done

   # Remove the tail ','
   result=${result%,}

   echo $result
}


#----------------------------------------------------------------
#
# getLongestStringLength --
#
#    Calculator length of the longest string in list.
#
#    Arguments:
#    List of string.
#
#----------------------------------------------------------------

function getLongestStringLength()
{
   local item
   local len_item
   local len_item_max=0

   for i in "$@"; do
      item=$i
      len_item=${#item}
      [ $len_item -gt $len_item_max ] && len_item_max=$len_item
   done

   echo $len_item_max
}


#----------------------------------------------------------------
#
# getMaxNumber --
#
#    Calculator the largest number in list.
#
#    Arguments:
#    List of number.
#
#----------------------------------------------------------------

function getMaxNumber()
{
   num_list=$1
   declare max_num=0

   for num in ${num_list[@]}; do
      [ $num -gt $max_num ] && max_num=$num
   done

   echo $max_num
}


#----------------------------------------------------------------
#
# get_home_dir --
#
#    Get home directory of a given user
#
#----------------------------------------------------------------

function get_home_dir()
{
   local user=$1
   eval echo "~$user"
}


#----------------------------------------------------------------
#
# is_permission_required --
#
#    Check if a permission is required to create/write a file
#    Return 1 when there is no permission, otherwise, return 0
#
#----------------------------------------------------------------

function is_permission_required()
{
   local file="$1"
   local dirpath=""

   file="${file/#~/$(get_home_dir $username)}"

   if ! [ -e $file ]; then
      dirpath=$(dirname "$file")
      if ! [ -e $dirpath ] && ! mkdir -p $dirpath 2>/dev/null; then
         return 1
      fi

      if ! [ -w $dirpath ]; then
         return 1
      fi
   elif ! [ -w $file ]; then
      return 1
   fi
}


#----------------------------------------------------------------
#
# contains_loglevel --
#
#    Check if a loglevel value list contains a loglevel value
#    The format of the list is value1,value2,value3
#    (Wildcard * is supported in the list to match any value)
#
#    Return 0 when value_list contains value
#    Return 1 when value_list does not contain value
#
#----------------------------------------------------------------

function contains_loglevel()
{
   local value_list="$1"
   local value="$2"
   local result=1

   IFS=',' read -ra values <<< "$value_list"

   for v in ${values[@]}; do
      if [ "$v" == "$value" ] || [ "$v" == "$CFG_ANY" ]; then
         result=0
         break
      fi
   done

   return $result
}


#----------------------------------------------------------------
#
# get_current_user --
#
#    Get current user running DCT script
#
#----------------------------------------------------------------

function get_current_user()
{
   local current_user

   if [ -n "$SUDO_USER" ]; then
      current_user=$SUDO_USER
   else
      current_user=$USER
   fi

   echo $current_user
}
