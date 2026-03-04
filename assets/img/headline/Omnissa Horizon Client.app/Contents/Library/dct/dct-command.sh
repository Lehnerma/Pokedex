#!/bin/bash
#
# Copyright (c) 2020 Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Public
#
# This script implements the Command line parameter parser for DCT.
# Analyze the parameters of the command, judge the validity of the
# parameters, and transfer them to the appropriate hanlder for processing
#

source "$DCT_PATH/plugin-manager.sh"
source "$DCT_PATH/collect-log-utils.sh"

# Sub flag of QUERY_LOGLEVEL for querying log level detail
QUERY_DETAIL=0

# Define global variable
DCT_ALL="ALL"
DCT_DEFAULT="DEFAULT"
DCT_LOG_TIME_LATEST="latest"
SPECIFY_SAVE_DIR=0
SPECIFY_SAVE_NAME=0
SPECIFY_COLLECT_DATA=0
SPECIFY_TIME_FILTER=0

declare -a loglevelConfigs
arguments=""
username=""

# Define global variable for log collection
target="${DEFAULT_DIR}${DEFAULT_TARGET}"
targetDirectory=""
logPackageName="${DEFAULT_TARGET}"
tmpdir=""
dctTargetDir=""
dctTargetName=""
dctLogTimeFilter=""

# Define global variable for DCT logger
cmd_args="$0 $@"
dct_log_file=""

#----------------------------------------------------------------
#
# parse_options --
#
#    Parse command line options of DCT
#
#    Arguments:
#    Arguments of DCT script
#
#----------------------------------------------------------------

function parse_options()
{
   # Init logger for DCT script
   initLogger

   # Parse Input options
   while [ $# -ne 0 ]; do
      arg=$1
      shift
      case $arg in
      -c)
         # Collect the logs/dumps for all features or for the specified
         # feature/component
         COLLECT_DATA=1
         SPECIFY_COLLECT_DATA=1
         arguments="$1"
         shift
         ;;
      -x)
         # Set the log level for all features or for the specified
         # feature/component
         SET_LOGLEVEL=1
         COLLECT_DATA=0
         arguments="$1"
         parseSetLoglevelConfig "$1"
         shift
         ;;
      -l)
         # List the log level settings for all features or for the
         # specified feature/component
         QUERY_LOGLEVEL=1
         COLLECT_DATA=0
         if ! [[ "$1" =~ ^-.* ]]; then
            arguments="$1"
            shift
         fi
         ;;
      -ld)
         # List the log level detail settings for all features or for the
         # specified feature/component
         QUERY_LOGLEVEL=1
         QUERY_DETAIL=1
         COLLECT_DATA=0
         if ! [[ "$1" =~ ^-.* ]]; then
            arguments="$1"
            shift
         fi
         ;;
      -r)
         # Reset log level to installation default
         RESET_LOGLEVEL=1
         COLLECT_DATA=0
         arguments="$DCT_ALL:$DCT_DEFAULT"
         parseSetLoglevelConfig "$arguments"
         ;;
      -h|--help)
         # Display the help information
         usage
         exit
         ;;
      -d)
         SPECIFY_SAVE_DIR=1
         dctTargetDir="$1"
         shift
         ;;
      -f)
         SPECIFY_SAVE_NAME=1
         dctTargetName="$1"
         shift
         ;;
      -t)
         # Support -t "latest" to collect log related to
         # latest launched client instance
         SPECIFY_TIME_FILTER=1
         dctLogTimeFilter="$1"
         shift
         ;;
      -u|--user)
         username="$1"
         shift
         ;;
      --)
         target="$@"
         shift $#
         ;;
      *)
         # For other options
         if [ ${arg:0:1} == '-' ]; then
            throw_exception "Unknown argument: $arg."
         else
            target="$arg"
         fi
         ;;
      esac
   done

   # Validate input options
   validateOptions

   # Set the user dct works for
   setUserName
}


#----------------------------------------------------------------
#
# query_loglevel --
#
#    Execute query loglevel command
#
#    Arguments:
#    Feature list to be queried (e.g "feature1,feature2,...")
#
#----------------------------------------------------------------

function query_loglevel()
{
   local args=$1
   local query_detail=$2

   # Init plugin manager
   init_plugin_manager

   if [ "$args" == "" ]; then
      query_loglevel_for_all $query_detail
   else
      IFS=, read -ra features <<< "$args"
      for feature in "${features[@]}"; do
         query_loglevel_for_plugin "$feature" $query_detail
      done
   fi

   # Finalize plugin manager
   finalize_plugin_manager
}


#----------------------------------------------------------------
#
# set_loglevel --
#
#    Execute set loglevel command
#
#----------------------------------------------------------------

function set_loglevel()
{
   # Init plugin manager
   init_plugin_manager

   # Call APIs of plugin manager to set log level
   for config in "${loglevelConfigs[@]}"; do
      IFS=: read -ra config_pair <<< "$config"
      local feature="${config_pair[0]}"
      local loglevel="${config_pair[1]}"

      if [ "$(toupper "$feature")" == "$DCT_ALL" ]; then
         set_loglevel_for_all "$loglevel"
      else
         set_loglevel_for_plugin "$feature" "$loglevel"
      fi
   done

   # Finalize plugin manager
   finalize_plugin_manager

   # Update shell context
   update_shell_context
}


#----------------------------------------------------------------
#
# collect_data --
#
#    Execute collect logs and dumps command
#
#    Arguments:
#    Feature list (e.g "feature1,feature2,...")
#
#----------------------------------------------------------------

function collect_data()
{
   local args="$1"
   local has_valid_logs=0

   # Pre-work for data collection
   preCollectData

   # Init plugin manager
   init_plugin_manager

   if [ "$args" == "" ] || [ "$(toupper "$args")" == $DCT_ALL ]; then
      collect_data_all
      has_valid_logs=1
   else
      IFS=, read -ra features <<< "$args"
      for feature in "${features[@]}"; do
         if collect_data_for_plugin "$feature" "$dctLogTimeFilter"; then
            has_valid_logs=1
         fi
      done
   fi

   # Finalize plugin manager
   finalize_plugin_manager

   # Package collected logs/dumps
   if [ $has_valid_logs == 1 ]; then
      packageData
   fi
}


#----------------------------------------------------------------
#
# usage --
#
#    Print usage of this script
#
#----------------------------------------------------------------

function usage()
{
cat <<EOF
Command line interface for Horizon Data Collection Tool (DCT) on Linux/Mac client.
Usage: ${0##*/} [options]

OPTIONS:
   -h, --help                    Show help information.
   -c <featureName>              Collect logs for features supported by DCT.
                                 For a specific feature, type its short name. For all features, type All.
   -x <featureName>:<loglevel>   Set log level for features supported by DCT.
                                 For a specific feature, type its short name. For all features, type All.
                                 Log levels are INFO, DEBUG, TRACE, and VERBOSE.
   -l <featureName>              List log level for features supported by DCT.
                                 For a specific a feature, type its short name. For all features, do not type a feature name.
   -ld <featureName>             List log level details for features supported by DCT.
                                 For a specific a feature, type its short name. For all features, do not type a feature name.
   -r                            Reset log level for all features to installation defaults.
   -d <directory>                Specify the directory to redirect DCT output to.
   -f <bundleName>               Specify the full name of the log bundle file.
   -u, --user <userName>         Specify the user name to collect logs for.

EOF
   echo "Specified feature name:"
   displayFeatureName
}


#----------------------------------------------------------------
#
# displayFeatureName --
#
#    Print short name and full name of supported features by DCT
#
#----------------------------------------------------------------

function displayFeatureName()
{
   init_plugin_manager
   init_feature_name_list

   for ((i=0; i < ${#FEATURE_SHORT_NAME_LIST[@]}; i++)); do
      local short_name=${FEATURE_SHORT_NAME_LIST[$i]}
      local full_name=${FEATURE_FULL_NAME_LIST[$i]}
      printf "%-32s %s\n" "   <$short_name>" $full_name
   done
   echo

   finalize_plugin_manager
}


#----------------------------------------------------------------
#
# validateOptions --
#
#    Validate the combination of DCT options. Make sure the
#    parameters are valid and there are no conflicts between
#    multiple parameters
#
#----------------------------------------------------------------

function validateOptions()
{
   # Handle the input confliction
   if [ $((SPECIFY_COLLECT_DATA+SET_LOGLEVEL+QUERY_LOGLEVEL+RESET_LOGLEVEL)) -gt 1 ]; then
      throw_exception "Conflicting arguments '-x, -l, -ld, -c, -r' are specified."
   fi

   # Validate options for log/data collecting
   if [ $COLLECT_DATA -eq 1 ]; then
      validateLogCollectOptions
   fi
}


#----------------------------------------------------------------
#
# validateLogCollectOptions --
#
#    Validate DCT options for collecting data/logs
#
#----------------------------------------------------------------

function validateLogCollectOptions()
{
   if [ $SPECIFY_SAVE_DIR -eq 1 ]; then
      [ -z $dctTargetDir ] && throw_exception "Target directory is not specified for option -d <directory>."
   fi

   if [ $SPECIFY_SAVE_NAME -eq 1 ]; then
      [ -z $dctTargetName ] && throw_exception "Target bundle name is not specified for option -f <bundleName>."
      [[ "$dctTargetName" =~ ^-.* ]] && throw_exception "Invalid target bundle name '$dctTargetName' for option -f <bundleName>."
   fi

   if [ $SPECIFY_COLLECT_DATA -eq 1 ]; then
      [ -z "$arguments" ] && throw_exception "Feature/component is not specified for option -c <featureName>."
   fi

   if [ $SPECIFY_TIME_FILTER -eq 1 ]; then
      if [ -z "$dctLogTimeFilter" ]; then
         throw_exception "Time filter is not specified for option -t <timeFilter>."
      elif [ $(tolower $dctLogTimeFilter) != $DCT_LOG_TIME_LATEST ]; then
         log_error "Option '$dctLogTimeFilter' is not supported for -t."
      fi
   fi
}


#----------------------------------------------------------------
#
# checkLoglevelConfig --
#
#    Check if the log level config is valid
#    A valid config as "featureName:loglevel"
#
#    Arguments:
#    Loglevel configs
#
#----------------------------------------------------------------

function checkLoglevelConfig()
{
   declare -a config
   IFS=: read -ra config <<< "$@"

   if [ ${#config[@]} -ne 2 ]; then
      throw_exception "Invalid format for log level config."
   fi

   local feature="${config[0]}"
   local loglevel="${config[1]}"

   # Verify whether the input log level is valid
   if ! isValidLoglevel "$loglevel"; then
      throw_exception "Invalid log level config '$loglevel' specified for $feature"
   fi
}


#----------------------------------------------------------------
#
# parseSetLoglevelConfig --
#
#    Parse options for setting loglevel config
#    A valid config as <feature1:loglevel1,feature2:loglevel2 ...>
#
#    Arguments:
#    Arguments of set log level command
#
#----------------------------------------------------------------

function parseSetLoglevelConfig()
{
   local args=$1

   if [ "$args" == "" ]; then
      throw_exception "Log level configs for '-x' are not specified."
   fi

   # Split the input parameters <feature1:loglevel1,feature2:loglevel2 ..>
   IFS=, read -ra loglevelConfigs <<< "$args"
   for config in "${loglevelConfigs[@]}"; do
      checkLoglevelConfig "${config[@]}"

      # Retrive the feature name and log level settings
      IFS=: read -ra config_pair <<< "$config"
      local feature=$(toupper "${config_pair[0]}")
      local loglevel=$(toupper "${config_pair[1]}")

      # validate the settings
      if [[ "$feature" == $DCT_ALL && ${#loglevelConfigs[@]} -gt 1 ]]; then
         throw_exception "There should not be other configs when log level for 'All' is set."
      fi
   done
}


#----------------------------------------------------------------
#
# preCollectData --
#
#    Pre-works for data collection
#    (check directory, make temp dir)
#
#----------------------------------------------------------------

function preCollectData()
{
   local character

   # Define illegal characters to check whether target bundle name includes them or not
   declare -a illegal_character_list
   illegal_character_list=("/" ":")

   check_directory

   # Get log package name
   if [ -n "$dctTargetName" ]; then
      logPackageName="${dctTargetName}${LOG_PACKAGE_SUFFIX}"
      target="${DEFAULT_DIR}${logPackageName}"
   fi

   # Get the full path of target log package
   if [ -n "$dctTargetDir" ]; then
      if ! [ -e "$dctTargetDir" ]; then
         throw_exception "Failed to save logs to $dctTargetDir, the folder does not exist."
      fi
      target="$dctTargetDir/$logPackageName"
   fi

   logPackageName=$(basename $target)
   targetDirectory="${logPackageName%$LOG_PACKAGE_SUFFIX}"

   for character in ${illegal_character_list[@]}; do
      if [[ $targetDirectory =~ $character ]]; then
         throw_exception "Failed to create log bundle, bundle name includes illegal charactor '$character'."
      fi
   done

   # Create a temporary directory in which to work.
   if ! tmpdir=$(mktemp -d); then
      throw_exception "Failed to create temporary directory."
   fi

   if ! mkdir "$tmpdir/$targetDirectory"; then
      throw_exception "Failed to create $tmpdir/$targetDirectory."
   fi
}


#----------------------------------------------------------------
#
# set_package_attributes--
#
#    Set attributes(owner, read/write permission) for package file
#
#    Arguments:
#    Full path of log package
#
#----------------------------------------------------------------

function set_package_attributes()
{
   local package="$1"
   local groupname

   # Set owner to common user when running by 'sudo'
   if [ -n "$SUDO_USER" ]; then
      groupname=$(id -gn $SUDO_USER)
      chown $SUDO_USER:$groupname "$package"
   fi

   # Add read/write permission
   chmod u=rw,g=,o= "$package"
}


#----------------------------------------------------------------
#
# packageData --
#
#    Package collected logs/dumps into a zip bundle
#
#----------------------------------------------------------------

function packageData()
{
   # Move into the temp directory to prevent tar from prepending the
   # temp directory on the target directory.
   pushd "$tmpdir" >/dev/null
   package_dir "$logPackageName" "$targetDirectory"
   local result=$?
   popd >/dev/null

   if [ $result -eq 0 ]; then
      set_package_attributes "$tmpdir/$logPackageName"
      mv "$tmpdir/$logPackageName" "$target"
      log_info "Logs are collected to $target."
   else
      log_error "Unable to make $target."
   fi

   rm -rf "$tmpdir"
}


#----------------------------------------------------------------
#
# setUserName-
#
#    Set the user name that DCT set/query/collect log for.
#
#    - If -u options specified (username in not empty),
#      set username to config by -u options
#    - If no -u options (usernanme is empty) and executed by sudo,
#      set username to $SUDO_USER
#    - Otherwise, set the username to $USER
#
#----------------------------------------------------------------

function setUserName()
{
   if [ -z "$username" ]; then
      username=$(get_current_user)
   fi
}


#----------------------------------------------------------------
#
# initLogger --
#
#    Initialize logger for DCT script
#    Log file name is identified by timestamp with hour precision
#
#----------------------------------------------------------------

function initLogger()
{
   local dct_log_name="horizon-dct-`date "+%Y-%m-%d-%H"`.log"
   local dct_log_dir=$(get_dct_log_dir)

   dct_log_file="$dct_log_dir/$dct_log_name"

   # Create log file
   if ! [ -e "$dct_log_file" ]; then
      local cur_user=$(get_current_user)
      local group_name=$(id -gn $cur_user)

      # Create log dir if it does not already exist
      if ! [ -e "$dct_log_dir" ]; then
         mkdir -p "$dct_log_dir"
         chown $cur_user:$group_name "$dct_log_dir"
      fi

      touch "$dct_log_file"
      chown $cur_user:$group_name "$dct_log_file"
   fi

   # Print script name and pid to log file
   local separator=`printf '%.s*' {1..90}`
   log_debug "$separator"
   log_debug "Logging for DCT, running \"$cmd_args\" pid=$$."
   log_debug "$separator"
}
