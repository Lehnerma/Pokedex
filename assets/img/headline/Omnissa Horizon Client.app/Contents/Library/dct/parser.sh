#!/bin/bash
#
# Copyright (c) 2020 Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Public
#
# This script implements a JSON format parser.
# Usage: parse_json < inputfile
#


JSON_SPACE='[[:space:]]+'
JSON_ESCAPE='(\\[^u[:cntrl:]])'
JSON_CHAR='[^[:cntrl:]"\\]'
JSON_STRING="\"($JSON_ESCAPE|$JSON_CHAR)*\""

# The parsed JSON dictionary
JSON_DICT=""


#----------------------------------------------------------------
#
# throw --
#
#    Throw exception
#
#----------------------------------------------------------------

function throw()
{
   echo "$@" 1>&2
   exit 1
}


#----------------------------------------------------------------
#
# parse_value --
#
#    Parse a JSON value.
#    A JSON value can an object, array, string.
#
#    Arguments:
#    1: Current path of the parsed value in JSON file
#    2: Index/key for this parsed value
#
#----------------------------------------------------------------

function parse_value()
{
   local path="${1:+$1,}$2"
   read -r token

   case "$token" in
      '{')
         parse_object "$path"
         ;;
      '[')
         parse_array  "$path"
         ;;
      *)
         value=$token
         [ -n "$value" ] && echo "$path,$value"
         ;;
   esac
}


#----------------------------------------------------------------
#
# parse_object
#
#    Parse a JSON object.
#
#    Arguments:
#    Current path in JSON file
#
#----------------------------------------------------------------

function parse_object()
{
   local key

   read -r token
   if [ $token == '}' ]; then
      return
   fi

   while :
   do
      [[ $token =~ '"'*'"' ]] || throw "Expected a string, got ${token:-EOF}"
      key=$token

      read -r token
      [ $token == ':' ] || throw "Expected ':', got ${token:-EOF}"
      parse_value "$1" "$key"

      read -r token
      [ $token == '}' ] && break;
      [ $token == ',' ] || throw "Expected ',' or '}', got ${token:-EOF}"
      read -r token
   done
}


#----------------------------------------------------------------
#
# parse_array --
#
#    Parse a JSON array.
#
#    Arguments:
#    Current path in JSON file
#
#----------------------------------------------------------------

function parse_array()
{
   local index=0

   while :
   do
      parse_value "$1" "$index"
      index=$((index+1))
      read -r token
      [ $token == ']' ] && break;
      [ $token == ',' ] || throw "Expected ',' or ']', got ${token:-EOF}"
   done
}


#----------------------------------------------------------------
#
# tokenize --
#
#    Tokenize the JSON file to multiple line output.
#    Each line represents a JSON token.
#    Each token represents:
#    a symbol (e.g. '{' '[' ',' ':')
#    a string (e.g. "key" "value")
#
#----------------------------------------------------------------

function tokenize()
{
   grep -Eo "$JSON_STRING|$JSON_SPACE|." | grep -Ev "^$JSON_SPACE$"
}


#----------------------------------------------------------------
#
# parse_json --
#
#    Parse JSON file. Usage: parse_json < inputfile
#    This function parse json file into a dictionary, and each
#    item in the dict saved the path of a JSON value in the file
#    e.g.  "key1","key2",index,"key3","jsonValue"
#
#----------------------------------------------------------------

function parse_json()
{
   IFS=$'\n' JSON_DICT=($(tokenize | parse_value))

   # Error check
   read -r token
   case "$token" in
      '')
         ;;
      *)
         throw "Expected EOF, got $token"
         ;;
   esac
}
