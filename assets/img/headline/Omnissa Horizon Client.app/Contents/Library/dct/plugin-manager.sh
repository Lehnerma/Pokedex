#!/bin/bash
#
# Copyright (c) 2020 Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Public
#
# This script implements functions for plugin manager of DCT.
#

source "$DCT_PATH/parser.sh"
source "$DCT_PATH/plugin-utils.sh"
source "$DCT_PATH/utils.sh"

# labels in Json config file
CFG_FEATURE_NAME="featureName"
CFG_LOGLEVEL="logLevelSettings"
CFG_LOGCOLLECT="logCollectionSettings"
CFG_DUMPCOLLECT="dumpCollectionSettings"
CFG_TIPS="tips"
CFG_FILES="files"
CFG_PATH="path"
CFG_PATHS="paths"
CFG_KEY="key"
CFG_DEFAULT="defaultValue"
CFG_ENV_VAR="envVariables"
CFG_VAR="variable"
CFG_USER_DEFAULTS="userDefaults"
CFG_DOMAIN="domain"
CFG_LOGLEVEL_MAP="logLevelMapping"
CFG_SRC="srcfolder"
CFG_TGT="tgtfolder"
CFG_RULE="rule"
CFG_TYPE="type"
CFG_MAIN="main"

# keywords for loglevel mapping
CFG_UNSET="UNSET"
CFG_ANY="*"

# patterns to seach Json value in dict
PATTERN_FEATURE_NAME="\"$CFG_FEATURE_NAME\","
PATTERN_LOGLEVEL_FILE="\"$CFG_LOGLEVEL\",\"$CFG_FILES\",[0-9]*,"
PATTERN_LOGLEVEL_PATH="$PATTERN_LOGLEVEL_FILE\"$CFG_PATH\","
PATTERN_LOGLEVEL_KEY="$PATTERN_LOGLEVEL_FILE\"$CFG_KEY\","
PATTERN_LOGLEVEL_DEFAULTS="\"$CFG_LOGLEVEL\",\"$CFG_USER_DEFAULTS\",[0-9]*,"
PATTERN_LOGLEVEL_DEFAULTS_DOMAIN="$PATTERN_LOGLEVEL_DEFAULTS\"$CFG_DOMAIN\","
PATTERN_LOGLEVEL_DEFAULTS_KEY="$PATTERN_LOGLEVEL_DEFAULTS\"$CFG_KEY\","
PATTERN_LOGLEVEL_ENV="\"$CFG_LOGLEVEL\",\"$CFG_ENV_VAR\",[0-9]*,"
PATTERN_LOGLEVEL_ENV_VAR="$PATTERN_LOGLEVEL_ENV\"$CFG_VAR\","
PATTERN_LOGCOLLECT_PATH="\"$CFG_LOGCOLLECT\",\"$CFG_PATHS\",[0-9]*,"
PATTERN_LOGCOLLECT_SRC="$PATTERN_LOGCOLLECT_PATH\"$CFG_SRC\","
PATTERN_LOGCOLLECT_RULE="$PATTERN_LOGCOLLECT_PATH\"$CFG_RULE\","
PATTERN_DUMPCOLLECT_PATH="\"$CFG_DUMPCOLLECT\",\"$CFG_PATHS\",[0-9]*,"
PATTERN_DUMPCOLLECT_SRC="$PATTERN_DUMPCOLLECT_PATH\"$CFG_SRC\","
PATTERN_DUMPCOLLECT_RULE="$PATTERN_DUMPCOLLECT_PATH\"$CFG_RULE\","

# Index of config of Json value in dict
IDX_CFG_TYPE=0
IDX_LOGLEVEL_TYPE=1
IDX_LOGLEVEL_IDX=2
IDX_LOGLEVEL_ITEM=3
IDX_TIPS=2

DCT_QUERY_DISPLAY_LEN=4
DCT_QUERY_HINT_ALL="All components controlled by DCT and log level status are listed below:"
DCT_LOG_LEVELS=("INFO" "DEBUG" "TRACE" "VERBOSE" "DEFAULT")
LOGLEVEL_DEFAULT="DEFAULT"
LOGLEVEL_UNKNOWN="UNKNOWN"
LOGLEVEL_INFO="INFO"
LOGLEVEL_DEBUG="DEBUG"
LOGLEVEL_TRACE="TRACE"
LOGLEVEL_VERBOSE="VERBOSE"
LOGLEVEL_PARTIAL_INFO="PARTIAL_INFO"
LOGLEVEL_PARTIAL_DEBUG="PARTIAL_DEBUG"
LOGLEVEL_PARTIAL_TRACE="PARTIAL_TRACE"
LOGLEVEL_PARTIAL_VERBOSE="PARTIAL_VERBOSE"
LOGLEVEL_DEFAULT_VAL="1"
DCT_FILTER_LATEST="latest"

# Plugin types
PLUGIN_COMMON="COMMON"
PLUGIN_MAIN="MAIN"
PLUGIN_SUB="SUB"

# variables for log filter
filter_type=""
filter_time_before=0

# variables for config file items
declare -a PLUGIN_LIST
declare -a PATH_ALIAS_LIST
declare -a FEATURE_SHORT_NAME_LIST
declare -a FEATURE_FULL_NAME_LIST
declare -a file_paths
declare -a file_keys
declare -a file_default_vals
declare -a env_variables
declare -a userdefault_domains
declare -a userdefault_keys
feature_full_name=""
setloglevel_tips=""

# variables for detail log level
loglevel_not_set="NOT SET"

# list of path aliases
PATH_ALIAS_LIST=("OMNISSA_TMP_DIR" "OMNISSA_LOG_DIR" "CLIENT_UI_DIR" "PCOIP_LOG_DIR")


#----------------------------------------------------------------
#
# init_plugin_manager --
#
#    Init plugin manager
#
#----------------------------------------------------------------

function init_plugin_manager()
{
   # Set global IFS to \n for there is space in path name
   GLOBAL_IFS=$IFS
   IFS=$'\n'

   # Init the plugin config file list
   PLUGIN_LIST=(`find "$CONFIG_PATH" -type f -name "*.json" -print | sort`)
}


#----------------------------------------------------------------
#
# finalize_plugin_manager --
#
#    Finalize plugin manager
#
#----------------------------------------------------------------

function finalize_plugin_manager()
{
   # Restore the global IFS
   IFS=$GLOBAL_IFS
}


#----------------------------------------------------------------
#
# init_feature_name_list --
#
#    Init feature name list
#
#----------------------------------------------------------------

function init_feature_name_list()
{
   for file in ${PLUGIN_LIST[@]}; do
      local short_name=$(getPluginName $file)
      FEATURE_SHORT_NAME_LIST+=($short_name)
      parse_json < $file
      local full_name=$(getFeatureName)
      FEATURE_FULL_NAME_LIST+=($full_name)
   done
}


#----------------------------------------------------------------
#
# set_loglevel_for_all --
#
#    Set log level for all plugin features
#
#    Arguments:
#    log level config(INFO/TRACE/DEBUG/VERBOSE)
#
#----------------------------------------------------------------

function set_loglevel_for_all()
{
   local loglevel=$1

   for file in ${PLUGIN_LIST[@]}; do
      [ $(getPluginType $file) == $PLUGIN_SUB ] && continue
      set_loglevel_by_plugin_config_file "$file" "$loglevel"
   done
}


#----------------------------------------------------------------
#
# set_loglevel_for_plugin --
#
#    Set log level for specific plugin feature.
#
#    Arguments:
#    1. feature name
#    2. log level config
#
#----------------------------------------------------------------

function set_loglevel_for_plugin()
{
   local name="$1"
   local loglevel=$2
   local config_file
   local plugin_type
   local plugin_name
   local status=0

   config_file=$(getPluginConfigFile "$name")
   [ -z "$config_file" ] && return 1

   plugin_type=$(getPluginType "$config_file")
   plugin_name=$(getPluginName "$config_file")

   # For a sub-feature, the config for its main feature should be executed
   if [ $plugin_type == $PLUGIN_SUB ]; then
      local main_feature=$(getMainFeature "$plugin_name")
      local main_feature_config=$(getPluginConfigFile "$main_feature")
      set_loglevel_by_plugin_config_file "$main_feature_config" "$loglevel" "$PLUGIN_MAIN"
      status=$?
   fi

   if [ $status -eq 0 ]; then
      set_loglevel_by_plugin_config_file "$config_file" "$loglevel"
   fi
}


#----------------------------------------------------------------
#
# set_loglevel_by_plugin_config_file --
#
#    Set log level for specific plugin feature based on its plugin
#    JSON config file
#
#    Arguments:
#    1. JSON config file path
#    2. log level config
#    3. plugin type (default is COMMON)
#
#----------------------------------------------------------------

function set_loglevel_by_plugin_config_file()
{
   local config_file="$1"
   local loglevel=$(toupper $2)
   local type="${3:-$PLUGIN_COMMON}"
   local status=0

   [ ! -f "$config_file" ] && return 1

   # Parse config file for the specified plugin feature
   parseConfigFile "$config_file" "$type"

   # Check installation status
   local plugin_name=$(getPluginName "$config_file")
   if ! check_installation_status "$plugin_name"; then
      log_info "$feature_full_name is not installed on Horizon Client."
      return 1
   fi

   # There might be failure setting log level in file due to permission
   if ! setLoglevelInFile "$loglevel"; then
      status=1
   fi

   setLoglevelInEnvVar "$loglevel"
   setLoglevelInUserDefaults "$loglevel"

   if [ $status -eq 0 ] && [ $type != $PLUGIN_MAIN ]; then
      log_info "Log level for $feature_full_name ($plugin_name) is set to $loglevel"
   fi

   # Print extra tip message
   [ -n "$setloglevel_tips" ] && echo "  $setloglevel_tips"

   return $status
}


#----------------------------------------------------------------
#
# query_loglevel_for_all --
#
#    Query the log level of all plugin features supported by DCT
#
#----------------------------------------------------------------

function query_loglevel_for_all()
{
   local query_detail=$1

   echo -e "$DCT_QUERY_HINT_ALL\n"

   queryLoglevelInDir "$CONFIG_PATH" 0 $query_detail
}


#----------------------------------------------------------------
#
# query_loglevel_for_plugin --
#
#    Query the log level of specifed feature
#
#    Arguments:
#    Feature name to be queried
#
#----------------------------------------------------------------

function query_loglevel_for_plugin()
{
   local feature_name=$1
   local query_detail=$2
   local config_file=$(getPluginConfigFile "$feature_name")

   [ -z "$config_file" ] && return

   local plugin_type=$(getPluginType "$config_file")

   if [ $plugin_type == $PLUGIN_MAIN ]; then
      local dir_name=`dirname $config_file`
      queryLoglevelInDir "$dir_name" 1 $query_detail
   else
      queryLoglevelForPluginConfig "$config_file" 0 $query_detail
   fi
}


#----------------------------------------------------------------
#
# collect_data_for_plugin --
#
#    Collect logs and dumps for specifed feature
#
#    Arguments:
#    1. Feature name
#    2. Filter option specified to collect data (currently only option
#       "latest" is supported)
#
#----------------------------------------------------------------

function collect_data_for_plugin()
{
   local feature_name=$1
   local filter_option="$2"
   local result

   if config_file=$(getPluginConfigFile "$feature_name"); then
      collect_data_by_plugin_config "$config_file" "$filter_option"
      result=0
   else
      result=1
   fi

   # Logs for DCT script are also collected
   collectDCTLogs

   return $result
}


#----------------------------------------------------------------
#
# parseConfigFile --
#
#    Parse config for plugin feature/components
#
#    Arguments:
#    1. Config file
#    2. Plugin type (default is COMMON)
#
#----------------------------------------------------------------

function parseConfigFile()
{
   local config_file="$1"
   local type="${2-$PLUGIN_COMMON}"

   # Parse Json config file for the specified feature
   parse_json < "$config_file"

   # Parse the config items for loglevel
   parseLoglevelConfig

   # Parse main module config
   parseMainModuleConfig "$type"

   # Get full name of feature
   feature_full_name=$(getFeatureName)
}


#----------------------------------------------------------------
#
# parseLoglevelConfig --
#
#    Parse JSON config file to get log level configs, generate
#    arrays for "files" config and "user defaults" config.
#
#----------------------------------------------------------------

function parseLoglevelConfig()
{
   local configs
   local cfg_type
   local cfg_len
   local loglevel_cfg_type
   local loglevel_cfg_idx
   local loglevel_cfg_item
   local loglevel_cfg_val

   # Reset following configs to empty
   unset file_paths
   unset file_keys
   unset file_default_vals
   unset env_variables
   unset userdefault_domains
   unset userdefault_keys
   setloglevel_tips=""

   for item in ${JSON_DICT[@]}; do
      IFS=',' read -ra configs <<< "$item"
      cfg_type=${configs[$IDX_CFG_TYPE]}
      cfg_len=${#configs[@]}

      if [ "$cfg_type" == "\"$CFG_LOGLEVEL\"" ]; then
         loglevel_cfg_type=${configs[$IDX_LOGLEVEL_TYPE]}
         loglevel_cfg_idx=${configs[$IDX_LOGLEVEL_IDX]}
         loglevel_cfg_item=${configs[$IDX_LOGLEVEL_ITEM]}
         loglevel_cfg_val=${configs[$cfg_len-1]}

         if [ "$loglevel_cfg_type" == "\"$CFG_FILES\"" ]; then
            addItemToFilesConfig $loglevel_cfg_idx $loglevel_cfg_item $loglevel_cfg_val
         elif [ "$loglevel_cfg_type" == "\"$CFG_ENV_VAR\"" ]; then
            addItemToEnvVariablesConfig $loglevel_cfg_item $loglevel_cfg_val
         elif [ "$loglevel_cfg_type" == "\"$CFG_USER_DEFAULTS\"" ]; then
            addItemToUserDefaultsConfig $loglevel_cfg_item $loglevel_cfg_val
         elif [ "$loglevel_cfg_type" == "\"$CFG_TIPS\"" ]; then
            setloglevel_tips=${configs[$IDX_TIPS]}
         fi
      fi
   done
}


#----------------------------------------------------------------
#
# parseMainModuleConfig --
#
#    Parse JSON config file to handle main module specific configs
#
#    If the plugin is parsed as a MAIN part (type is "main") for
#    a sub-module, the config with "type" is "main" will be ignored.
#
#    Arguments:
#    Plugin type
#
#----------------------------------------------------------------

function parseMainModuleConfig()
{
   local type="$1"

   # Only parse for main module
   [ "$type" != "$PLUGIN_MAIN" ] && return

   for item in ${JSON_DICT[@]}; do
      IFS=',' read -ra configs <<< "$item"
      cfg_type=${configs[$IDX_CFG_TYPE]}

      [ "$cfg_type" != "\"$CFG_LOGLEVEL\"" ] && continue

      cfg_len=${#configs[@]}
      loglevel_cfg_type=${configs[$IDX_LOGLEVEL_TYPE]}
      loglevel_cfg_idx=${configs[$IDX_LOGLEVEL_IDX]}
      loglevel_cfg_item=${configs[$IDX_LOGLEVEL_ITEM]}
      loglevel_cfg_val=${configs[$cfg_len-1]}

      if [ "$loglevel_cfg_type" == "\"$CFG_FILES\"" ] && \
         [ "$loglevel_cfg_item" == "\"$CFG_TYPE\"" ] && \
         [ "$loglevel_cfg_val" == "\"$CFG_MAIN\"" ]; then
         local idx=$(trim $loglevel_cfg_idx)
         unset file_paths[$idx]
         unset file_keys[$idx]
      fi
   done
}


#----------------------------------------------------------------
#
# addItemToFilesConfig --
#
#    Add config value for "path" and "key" to paths and keys list
#    for "files" config.
#    Each "path" and "key" item can be a list of value by descending
#    priority order
#
#    Arguments:
#    1. Index of item in "files" config
#    2. Type of the item
#    3. Value of the item
#
#----------------------------------------------------------------

function addItemToFilesConfig()
{
   local idx=$1
   local cfg_item="$2"
   local cfg_val="$3"

   if [ "$cfg_item" == "\"$CFG_PATH\"" ]; then
      file_paths[$idx]+="$cfg_val,"
   elif [ "$cfg_item" == "\"$CFG_KEY\"" ]; then
      file_keys[$idx]+="$cfg_val,"
   elif [ "$cfg_item" == "\"$CFG_DEFAULT\"" ]; then
      file_default_vals[$idx]="$cfg_val"
   fi
}


#----------------------------------------------------------------
#
# addItemToEnvVariablesConfig --
#
#    Add config value for "variable" to variables list
#    for "envVariables" config.
#
#    Arguments:
#    1. Type of the item
#    2. Value of the item
#
#----------------------------------------------------------------

function addItemToEnvVariablesConfig()
{
   local cfg_item="$1"
   local cfg_val="$2"

   if [ "$cfg_item" == "\"$CFG_VAR\"" ]; then
      env_variables+=($cfg_val)
   fi
}


#----------------------------------------------------------------
#
# addItemToUserDefaultsConfig --
#
#    Add config value for "domain" and "key" to domains and keys
#    list for "userDefaults" config.
#
#    Arguments:
#    1. Type of the item
#    2. Value of the item
#
#----------------------------------------------------------------

function addItemToUserDefaultsConfig()
{
   local cfg_item="$1"
   local cfg_val="$2"

   if [ "$cfg_item" == "\"$CFG_DOMAIN\"" ]; then
      userdefault_domains+=($cfg_val)
   elif [ "$cfg_item" == "\"$CFG_KEY\"" ]; then
      userdefault_keys+=($cfg_val)
   fi
}


#----------------------------------------------------------------
#
# readLoglevelFromIniConfigFile --
#
#    Read loglevel value from config file in INI format.
#
#    Arguments:
#    1. Config file path
#    2. Key of the loglevel config
#
#----------------------------------------------------------------

function readLoglevelFromIniConfigFile()
{
   local path=$1
   local key=$2
   local result=""

   path=$(trim $path)
   path="${path/#~/$(get_home_dir $username)}"
   key=$(trim $key)

   if [ -e $path ]; then
      local item=`grep "$key" $path | tail -1`
      item="$(echo -e "${item}" | tr -d '[:space:]')"

      IFS='=' read -ra config <<< "$item"

      if [ ${#config[@]} -eq 2 ]; then
         result=${config[1]}
      fi
   fi

   echo $result
}


#----------------------------------------------------------------
#
# getLoglevelByJSONConfig --
#
#    Get loglevel results from parsed plugin config.
#
#----------------------------------------------------------------

function getLoglevelByJSONConfig()
{
   local loglevels

   # Query log level in ini config file
   loglevels=$(queryLoglevelInIniConfig)

   # Query log level in env variable
   if [ "$loglevels" == "" ]; then
      loglevels=$(queryLoglevelInEnv)
   fi

   # Query log level in user's defaults
   if [ "$loglevels" == "" ]; then
      loglevels=$(queryLoglevelInUserDefaults)
   fi

   if [ "$loglevels" == "" ]; then
      loglevels=$LOGLEVEL_DEFAULT
   fi

   echo $loglevels
}


#----------------------------------------------------------------
#
# queryLoglevelForPluginConfig --
#
#    Query the log level of a plugin feature by config file.
#
#    Arguments:
#    1. plugin config file path
#    2. depth of plugin config file in dct config folder
#
#----------------------------------------------------------------

function queryLoglevelForPluginConfig()
{
   local file=$1
   local depth=$2
   local query_detail=$3
   local loglevel=""
   local loglevels=""
   local loglevels_main=""
   local indent=""
   local plugin_type=$(getPluginType $file)
   local plugin_name=$(getPluginName $file)
   local main_plugin_name
   local main_plugin_file
   local display_name

   # Check if plugin is main or sub feature
   if [ $plugin_type == $PLUGIN_SUB ]; then
      main_plugin_name=$(getMainFeature "$plugin_name")
   fi

   [ -z $main_plugin_name ] && main_plugin_name="$plugin_name"

   # Check installation status
   if ! check_installation_status "$main_plugin_name"; then
      return 1
   fi

   # Parse Config file for the specified feature
   parseConfigFile "$file"
   loglevels=$(getLoglevelByJSONConfig)
   display_name=$feature_full_name

   # If the feature is a sub-feature, need query its main feature
   if [ $plugin_type == $PLUGIN_SUB ]; then
      main_plugin_file=$(getPluginConfigFile "$main_plugin_name")
      parseConfigFile "$main_plugin_file" "$PLUGIN_MAIN"
      loglevels_main=$(getLoglevelByJSONConfig)
      loglevels=$(intersect $loglevels $loglevels_main)
   fi

   [ -z "$loglevels" ] && loglevels=$LOGLEVEL_UNKNOWN

   # Use the first loglevel as the final value if result is multi-value
   IFS=',' read -ra loglevel_list <<< "$loglevels"
   loglevel=$(toupper ${loglevel_list[0]})

   # Print log level status for feature
   [ $depth -gt 1 ] && printf -v indent "%*s" $depth '  '
   local feature="$indent- $display_name"

   if [ $plugin_type != $PLUGIN_MAIN ]; then
      printf "%-50s %s\n" "$feature" [$loglevel]
      if [[ $query_detail -eq 1 ]]; then
         queryDetailLoglevel $indent
      fi
   fi
}


#----------------------------------------------------------------
#
# queryDetailLoglevel --
#
#    Query and display detail information of log level.
#
#    Arguments:
#    Current indent
#
#----------------------------------------------------------------

function queryDetailLoglevel()
{
   local indent=$1
   local detail_file_path
   local detail_file_key
   local detail_file_val
   local detail_env_variable
   local detail_env_val
   local detail_default_domain
   local detail_default_key
   local detail_default_val
   local detail_format=$(formatDetailLoglevel)
   declare -a path_list

   # For files
   for ((i=0; i < ${#file_paths[@]}; i++)); do
      detail_file_key=${file_keys[$i]}

      IFS=',' read -ra path_list <<< "${file_paths[$i]}"

      if [ ${#path_list[@]} != 1 ]; then
         printf "$indent  - The configuration is processed in the order listed:\n"
         for path_item in ${path_list[@]}; do
            detail_file_val=$(queryLoglevelFromPrioritizedIniFiles $path_item $detail_file_key)
            indent_priority="$indent    "
            queryDetailLoglevelForFile "$indent_priority" "$path_item" "$detail_file_key" "$detail_file_val"
         done
      else
         detail_file_path=${file_paths[$i]}
         detail_file_val=$(queryLoglevelFromPrioritizedIniFiles $detail_file_path $detail_file_key)
         indent_no_priority="$indent  - "
         queryDetailLoglevelForFile "$indent_no_priority" "$detail_file_path" "$detail_file_key" "$detail_file_val"
      fi
   done

   # For environment variables
   for ((i=0; i < ${#env_variables[@]}; i++)); do
      detail_env_variable=${env_variables[$i]}
      detail_env_val=$(read_loglevel_from_env $detail_env_variable)
      if [ -z "$detail_default_val" ]; then
         detail_env_val=$loglevel_not_set
      fi
      printf "$indent  - $detail_format \n" "$(trim ${detail_env_variable%\,})" \
         "$detail_env_val" ""
   done

   # For user defaults
   for ((i=0; i < ${#userdefault_domains[@]}; i++)); do
      detail_default_domain=${userdefault_domains[$i]}
      detail_default_key=${userdefault_keys[$i]}
      detail_default_val=$(read_loglevel_from_defaults $detail_default_domain $detail_default_key)
      if [ -z "$detail_default_val" ]; then
         detail_default_val=$loglevel_not_set
      fi
      printf "$indent  - $detail_format \n" "$(trim ${detail_default_domain%\,})" \
         "$(trim ${detail_default_key%\,})" "$detail_default_val"
   done
}


#----------------------------------------------------------------
#
# queryDetailLoglevelForFile --
#
#    Query and display detail information of log level for files.
#
#    Arguments:
#    1. current prefix
#    2. file path
#    3. file key
#    4. value for key
#
#----------------------------------------------------------------

function queryDetailLoglevelForFile()
{
   local prefix=$1
   local detail_file_path=$2
   local detail_file_key=$3
   local detail_file_val=$4

   if [ -z "$detail_file_val" ]; then
      detail_file_val=$loglevel_not_set
   fi
   printf "$prefix$detail_format \n" "$(trim ${detail_file_path%%\,*})" \
      "$(trim ${detail_file_key%\,})" "$detail_file_val"
}

#----------------------------------------------------------------
#
# formatDetailLoglevel --
#
#    Format detail information of log level.
#
#----------------------------------------------------------------

function formatDetailLoglevel()
{
   local path
   local key
   local var
   local domain
   declare -a file_path
   declare -a file_key
   declare -a env_variable
   declare -a userdefault_domain
   declare -a userdefault_key

   # Special handling for trim '"'/',' in each list item
   for ((i=0; i < ${#file_paths[@]}; i++)); do
      IFS=',' read -ra path_list <<< "${file_paths[$i]}"
      key=${file_keys[$i]}
      key=$(trim ${key%%\,*})
      for path_item in ${path_list[@]}; do
         path=$(trim $path_item)
         file_path+=($path)
         file_key+=($key)
      done
   done

   for ((i=0; i < ${#env_variables[@]}; i++)); do
      var=${env_variables[$i]}
      var=$(trim ${var%%\,*})
      env_variable+=($var)
   done

   for ((i=0; i < ${#userdefault_domains[@]}; i++)); do
      domain=${userdefault_domains[$i]}
      key=${userdefault_keys[$i]}
      domain=$(trim ${domain%%\,*})
      key=$(trim ${key%%\,*})
      userdefault_domain+=($domain)
      userdefault_key+=($key)
   done

   # Format detail information of log level
   local len_file_path_max=$(getLongestStringLength "${file_path[@]}")
   local len_file_key_max=$(getLongestStringLength "${file_key[@]}")
   local len_env_var_max=$(getLongestStringLength "${env_variable[@]}")
   local len_default_domain_max=$(getLongestStringLength "${userdefault_domain[@]}")
   local len_default_key_max=$(getLongestStringLength "${userdefault_key[@]}")

   declare -a column1=($len_file_path_max $len_env_var_max $len_default_domain_max)
   declare -a column2=($len_file_key_max $len_default_key_max)
   local len_column1_max=$(getMaxNumber "${column1[*]}")
   local len_column2_max=$(getMaxNumber "${column2[*]}")

   local detail_format="%-$[len_column1_max+2]s %-$[len_column2_max+2]s %s"

   echo $detail_format
}


#----------------------------------------------------------------
#
# queryLoglevelInDir --
#
#    Query the log level configs of plugin features by config files
#    under a folder.
#
#    Arguments:
#    1. Config file folder path
#    2. depth of config file folder in dct config folder
#
#----------------------------------------------------------------

function queryLoglevelInDir()
{
   local dir=$1
   local depth=$2
   local query_detail=$3
   local config_files=(`find "$dir" -maxdepth 1 -type f -name "*.json" -print | sort`)
   local subdirs=(`find "$dir" -maxdepth 1 -mindepth 1 -type d -print | sort`)

   if [ ${#config_files[@]} -gt 0 ] && [ $depth -gt 0 ]; then
      local component=`basename $dir`
      component=${component//_/ }
      [ $depth -gt 1 ] && printf -v indent "%*s" $depth '  '
      echo "$indent- $component"
   fi

   for file in "${config_files[@]}"; do
      queryLoglevelForPluginConfig "$file" $[depth+1] $query_detail
   done

   for subdir in "${subdirs[@]}"; do
      queryLoglevelInDir "$subdir" $[depth+1] $query_detail
   done
}


#----------------------------------------------------------------
#
# queryLoglevelFromPrioritizedIniFiles --
#
#    Query the log level config from a list of INI config files
#    and keys (path and key configs are descending ordered on priority)
#
#    Arguments:
#    1. path configs
#    2. key configs
#
#----------------------------------------------------------------

function queryLoglevelFromPrioritizedIniFiles()
{
   local path_cfg=$1
   local key_cfg=$2
   local path_list
   local key_list
   local multi_key=0
   local path
   local key
   local result

   IFS=',' read -ra path_list <<< "$path_cfg"
   IFS=',' read -ra key_list <<< "$key_cfg"
   [ ${#key_list[@]} -gt 1 ] && multi_key=1

   # Query log level from multiple paths and keys with priority
   for path in ${path_list[@]}; do
      if [ $multi_key -eq 1 ]; then
         key=${key_list[$j]}
      else
         key=${key_list[0]}
      fi
      result=$(readLoglevelFromIniConfigFile "$path" "$key")
      [ -n "$result" ] && break
   done

   if [ -n "$result" ]; then
      log_debug "loglevel config: $key in $path is $result"
   else
      log_debug "loglevel config: $key in $path is not set"
   fi

   echo $result
}


#----------------------------------------------------------------
#
# queryLoglevelInIniConfig --
#
#    Query the log level config in INI config file
#
#----------------------------------------------------------------

function queryLoglevelInIniConfig()
{
   local path_cfg
   local key_cfg
   local default_val
   local loglevels=""
   local standard_loglevels
   local loglevel_intersect=""

   for ((i=0; i < ${#file_paths[@]}; i++)); do
      path_cfg=${file_paths[$i]}
      key_cfg=${file_keys[$i]}
      default_val=${file_default_vals[$i]}
      [ -z "$key_cfg" ] && throw_exception "Invalid key config for $feature_full_name"
      local loglevel_in_file=$(queryLoglevelFromPrioritizedIniFiles $path_cfg $key_cfg)

      if [ -z "$loglevel_in_file" ]; then
         standard_loglevels=$LOGLEVEL_DEFAULT
      else
         local pattern_file="\"$CFG_LOGLEVEL\",\"$CFG_FILES\",$i,"
         standard_loglevels=$(getStandardLoglevel "$pattern_file" "$loglevel_in_file")
         if [[ "$standard_loglevels" == $LOGLEVEL_UNKNOWN ]]; then
            if [[ "$loglevel_in_file" == "$(trim $default_val)" ]]; then
               loglevels=$LOGLEVEL_DEFAULT
            else
               loglevels=$LOGLEVEL_UNKNOWN
            fi
            break
         fi
      fi

      # Get intersect of each config item
      if [ -z "$loglevels" ]; then
         loglevels=$standard_loglevels
      else
         loglevel_intersect=$(intersect $loglevels $standard_loglevels)
         [ -z "$loglevel_intersect" ] && loglevels=$(handleLoglevel $loglevels $standard_loglevels)
      fi
   done

   echo $loglevels
}


#----------------------------------------------------------------
#
# queryLoglevelInEnv --
#
#    Query the log level config in environment variable config
#
#----------------------------------------------------------------

function queryLoglevelInEnv()
{
   local loglevels

   for item in ${JSON_DICT[@]}; do
      if [[ $item =~ $PATTERN_LOGLEVEL_ENV_VAR ]]; then
         local variable=${item##$PATTERN_LOGLEVEL_ENV_VAR}
         local loglevel_in_env=$(read_loglevel_from_env $variable)
         if [ -z "$loglevel_in_env" ]; then
            loglevel_in_env=$CFG_UNSET
         fi
         loglevels=$(getStandardLoglevel "$PATTERN_LOGLEVEL_ENV" "$loglevel_in_env")
      fi
   done

   echo $loglevels
}


#----------------------------------------------------------------
#
# setLoglevelInEnvVar --
#
#    Set log level with environment variable.
#
#    Arguments:
#    log level config
#
#----------------------------------------------------------------

function setLoglevelInEnvVar()
{
   local loglevel=$1
   local mapped_loglevel=""
   local variable=""

   for item in ${JSON_DICT[@]}; do
      if [[ $item =~ $PATTERN_LOGLEVEL_ENV_VAR ]]; then
         variable=${item##$PATTERN_LOGLEVEL_ENV_VAR}
         item=${item%%,\"variable\",$variable}

         if [ "$loglevel" == "$LOGLEVEL_DEFAULT" ]; then
            unsetEnvVar "$variable"
         else
            mapped_loglevel=$(getMappedLoglevel "$item" "$loglevel")
            if [ "$mapped_loglevel" == "$CFG_UNSET" ]; then
               unsetEnvVar "$variable"
            else
               setEnvVar "$variable" "$mapped_loglevel"
            fi
         fi
      fi
   done
}


#----------------------------------------------------------------
#
# setLoglevelInFile --
#
#    Set log level in config file.
#
#    Arguments:
#    log level config
#
#----------------------------------------------------------------

function setLoglevelInFile()
{
   local loglevel=$1
   local loglevel_to_file=""
   local path_cfg=""
   local key_cfg=""
   local path=""
   local key=""
   local path_list
   local key_list
   local multi_key=0
   local loglevel_operation="set"
   declare -a set_paths
   declare -a set_keys
   declare -a set_vals
   declare -a default_vals

   for ((i=0; i < ${#file_paths[@]}; i++)); do
      path_cfg=${file_paths[$i]}
      key_cfg=${file_keys[$i]}
      default_val=${file_default_vals[$i]}
      [ -z "$key_cfg" ] && throw_exception "Invalid key config for $feature_full_name"

      if [ $loglevel != "$LOGLEVEL_DEFAULT" ]; then
         # Get mapped log level for the config item
         local pattern_file="\"$CFG_LOGLEVEL\",\"$CFG_FILES\",$i"
         loglevel_to_file=$(getMappedLoglevel "$pattern_file" "$loglevel")
      else
         loglevel_to_file=$default_val
      fi

      # Handle multiple paths and keys for the config item
      IFS=',' read -ra path_list <<< "$path_cfg"
      IFS=',' read -ra key_list <<< "$key_cfg"
      [ ${#key_list[@]} -gt 1 ] && multi_key=1

      # Check if there is permission to set log level in the priority file list
      local permission=0
      for ((j=0; j < ${#path_list[@]}; j++)); do
         path=${path_list[$j]}
         [ $multi_key -eq 1 ] && key=${key_list[$j]} || key=${key_list[0]}

         if is_permission_required "$(trim $path)"; then
            permission=1
            set_paths+=($path)
            set_keys+=($key)
            set_vals+=($loglevel_to_file)
         fi
      done

      [ $RESET_LOGLEVEL == 1 ] && loglevel_operation="reset"
      if [ $permission -eq 0 ]; then
         log_info "Failed to $loglevel_operation log level for $feature_full_name, root permission is required, please use 'sudo <command>'"
         return 1
      fi
   done

   # Execute the set loglevel, update INI config file
   for ((i=0; i < ${#set_paths[@]}; i++)); do
      local set_path=${set_paths[i]}
      local set_key=${set_keys[i]}
      local set_val=${set_vals[i]}

      if [ "$loglevel" == "$LOGLEVEL_DEFAULT" ]; then
         if [ -n "$set_val" ]; then
            writeConfigToIniFile "$set_path" "$set_key" "$default_val"
         else
            deleteConfigFromIniFile "$set_path" "$set_key"
         fi
      else
         writeConfigToIniFile "$set_path" "$set_key" "$set_val"
      fi
   done
}


#----------------------------------------------------------------
#
# queryLoglevelInUserDefaults --
#
#    Query the log level in user's defaults config
#
#----------------------------------------------------------------

function queryLoglevelInUserDefaults()
{
   local standard_loglevel=""
   local loglevels=""
   local loglevel_intersect=""

   for ((i=0; i < ${#userdefault_domains[@]}; i++)); do
      local domain=${userdefault_domains[$i]}
      local key=${userdefault_keys[$i]}
      [ -z $key ] && throw_exception "There is not matching key for domain $domain"
      local loglevel_in_defaults=$(read_loglevel_from_defaults $domain $key)

      local standard_loglevels=""
      if [ -n "$loglevel_in_defaults" ]; then
         local pattern_defaults="\"$CFG_LOGLEVEL\",\"$CFG_USER_DEFAULTS\",$i,"
         standard_loglevels=$(getStandardLoglevel "$pattern_defaults" "$loglevel_in_defaults")
         [[ "$standard_loglevels" == $LOGLEVEL_UNKNOWN ]] && loglevels=$LOGLEVEL_UNKNOWN && break;
      fi

      # Get intersect of each config item
      if [ -z "$loglevels" ]; then
         loglevels=$standard_loglevels
      else
         loglevel_intersect=$(intersect $loglevels $standard_loglevels)
         [ -z "$loglevel_intersect" ] && loglevels=$(handleLoglevel $loglevels $standard_loglevels)
      fi
   done

   echo $loglevels
}


#----------------------------------------------------------------
#
# setLoglevelInUserDefaults --
#
#    Set log level within user defaults.
#
#    Arguments:
#    log level config
#
#----------------------------------------------------------------

function setLoglevelInUserDefaults()
{
   local loglevel=$1
   local mapped_loglevel=""

   for ((i=0; i < ${#userdefault_domains[@]}; i++)); do
      local domain=${userdefault_domains[$i]}
      local key=${userdefault_keys[$i]}
      [ -z $key ] && throw_exception "There is not matching key for domain $domain"

      if [ "$loglevel" == "$LOGLEVEL_DEFAULT" ]; then
         delete_user_defaults "$domain" "$key"
      else
         local pattern_defaults="\"$CFG_LOGLEVEL\",\"$CFG_USER_DEFAULTS\",$i"
         mapped_loglevel=$(getMappedLoglevel "$pattern_defaults" "$loglevel")
         write_user_defaults "$domain" "$key" "$mapped_loglevel"
      fi
   done
}


#----------------------------------------------------------------
#
# getPluginName --
#
#    Retrieve plugin name from a full path of a plugin JSON config file
#
#    Arguments:
#    Full path of plugin JSON config file
#
#----------------------------------------------------------------

function getPluginName()
{
   local plugin_path=$1
   local plugin_name=""

   plugin_name=`basename $plugin_path`
   plugin_name=${plugin_name%%.json}
   plugin_name=${plugin_name//_/ }

   echo $plugin_name
}


#----------------------------------------------------------------
#
# getMainFeature --
#
#    Get main feature name for a feature.
#    If feature is not sub-feature, just return the feature name
#
#    Arguments:
#    Feature name
#
#----------------------------------------------------------------

function getMainFeature()
{
   local feature="$1"
   local main_feature=""

   # For a sub feature, the name format is
   # <Main>.<sub1>.<sub2> ...
   IFS='.' read -ra feature_names <<< $feature

   if [ ${#feature_names[@]} -gt 1 ]; then
      main_feature=${feature_names[0]}
   fi

   echo "$main_feature"
}


#----------------------------------------------------------------
#
# getPluginType --
#
#    Retrieve type of the plugin feature/component. The types
#    supported by DCT includes:
#    - COMMON: Common plugin that has no sub features
#    - MAIN: Plugin that represents a main module. The plugin owns
#            a folder with the plugin name, and plugins of its
#            sub-features are under the same folder.
#    - SUB: Plugin is a sub-feature of a MAIN plugin
#
#    Arguments:
#    Full path of plugin JSON config file
#
#----------------------------------------------------------------

function getPluginType()
{
   local plugin_path="$1"
   local plugin_name
   local dir_name
   local plugin_type=$PLUGIN_COMMON

   dir_name=`dirname $plugin_path`
   dir_name=`basename $dir_name`

   plugin_name=`basename $plugin_path`
   plugin_name=${plugin_name%%.json}

   if [ "$plugin_name" == "$dir_name" ]; then
      plugin_type=$PLUGIN_MAIN
   elif [ "$(getMainFeature $plugin_name)" == "$dir_name" ]; then
      plugin_type=$PLUGIN_SUB
   fi

   echo $plugin_type
}


#----------------------------------------------------------------
#
# getFeatureName --
#
#    Retrieve full name of plugin feature/component from plugin
#    JSON config file
#
#----------------------------------------------------------------

function getFeatureName()
{
   local feature_name=""

   for item in ${JSON_DICT[@]}; do
      if [[ $item =~ $PATTERN_FEATURE_NAME ]]; then
         feature_name=${item##$PATTERN_FEATURE_NAME}
         break
      fi
   done

   echo $(trim $feature_name)
}


#----------------------------------------------------------------
#
# getPluginConfigFile --
#
#    Given a feature name, get the path of corresponding plugin
#    JSON config file
#
#    Arguments:
#    Feature name
#
#----------------------------------------------------------------

function getPluginConfigFile()
{
   local feature_name=$(tolower "$1")
   local plugin_name=""
   local plugin_path=""

   for file in ${PLUGIN_LIST[@]}; do
      plugin_name="$(tolower "$(getPluginName $file)")"
      if [ "$feature_name" == "$plugin_name" ]; then
         plugin_path=$file
         break
      fi
   done

   if [ -z $plugin_path ]; then
      log_error "Feature $feature_name is not supported by DCT"
      return 1
   fi

   echo $plugin_path
   return 0
}


#----------------------------------------------------------------
#
# handleLoglevel --
#
#    Handle two log levels to get proper log level result.
#
#    - If any of the two log levels is "DEFAULT", return
#      "PARTIAL_XXX" associated to another log level.
#    - If one log level is "PARTIAL_XXX" which is associated
#      to another log level, return "PARTIAL_XXX".
#    - Otherwise, return "UNKNOWN"
#
#----------------------------------------------------------------

function handleLoglevel()
{
   local src=$1
   local tgt=$2
   local result=$LOGLEVEL_UNKNOWN

   src=$(trim ${src%%\,*})
   tgt=$(trim ${tgt%%\,*})

   if [ "$src" == "$LOGLEVEL_DEFAULT" ]; then
      result=$(mapAssociatedLoglevels $tgt)
   elif [ "$tgt" == "$LOGLEVEL_DEFAULT" ]; then
      result=$(mapAssociatedLoglevels $src)
   elif [[ $(mapAssociatedLoglevels $tgt) == $src ]]; then
      result=$src
   fi

   echo $result
}


#----------------------------------------------------------------
#
# mapAssociatedLoglevels --
#
#    Map associate loglevels
#
#----------------------------------------------------------------

function mapAssociatedLoglevels()
{
   local loglevel=$1
   local result=$loglevel

   if [ "$loglevel" == "$LOGLEVEL_DEFAULT" ]; then
      result=$LOGLEVEL_DEFAULT
   elif [ "$loglevel" == "$LOGLEVEL_INFO" ]; then
      result=$LOGLEVEL_PARTIAL_INFO
   elif [ "$loglevel" == "$LOGLEVEL_DEBUG" ]; then
      result=$LOGLEVEL_PARTIAL_DEBUG
   elif [ "$loglevel" == "$LOGLEVEL_TRACE" ]; then
      result=$LOGLEVEL_PARTIAL_TRACE
   elif [ "$loglevel" == "$LOGLEVEL_VERBOSE" ]; then
      result=$LOGLEVEL_PARTIAL_VERBOSE
   fi

   echo $result
}


#----------------------------------------------------------------
#
# getMappedLoglevel --
#
#    Get loglevel config from loglevel mapping in config file
#
#    Arguments:
#    1. Files/envVariables object containing loglevel mapping
#    2. log level config
#
#----------------------------------------------------------------

function getMappedLoglevel()
{
   local object=$1
   local loglevel=$2
   local pattern_mapping="$object,\"$CFG_LOGLEVEL_MAP\",\"$loglevel\","
   local mapped_loglevel=""
   local mapped_loglevel_list

   for item in ${JSON_DICT[@]}; do
      if [[ $item =~ $pattern_mapping ]]; then
         mapped_loglevel=${item##$pattern_mapping}
      fi
   done

   IFS=',' read -ra mapped_loglevel_list <<< $(trim $mapped_loglevel)

   # If there are multiple values in mapped loglevel list
   # Use the first value as mapped loglevel
   if [ ${#mapped_loglevel_list[@]} -gt 0 ]; then
      mapped_loglevel=${mapped_loglevel_list[0]}
   fi

   # If mapped loglevel is wilcard, use "1" as the actual value
   if [ "$mapped_loglevel" == "\"$CFG_ANY\"" ]; then
      mapped_loglevel="$LOGLEVEL_DEFAULT_VAL"
   fi

   if [ -z $mapped_loglevel ]; then
      mapped_loglevel=$(tolower $loglevel)
   fi

   echo $mapped_loglevel
}


#----------------------------------------------------------------
#
# getStandardLoglevel --
#
#    Get standard loglevel value(INFO/DEBUG/TRACE/VERBOSE) for DCT
#    from the given specific loglevel of a feature
#
#    If the given specific loglevel of a feature matches multiple
#    standard loglevel value, the result are organized as list
#    (e.g. "INFO,DEBUG,TRACE")
#
#    If the given specific loglevel of a feature matches nothing,
#    the result is "UNKNOWN"
#
#    Arguments:
#    1. Files/envVariables object containing loglevel mapping
#    2. feature log level config
#
#----------------------------------------------------------------

function getStandardLoglevel()
{
   local object=$1
   local loglevel=$2
   local pattern_map_obj="$object\"$CFG_LOGLEVEL_MAP\","
   local pattern_map_item="$pattern_map_obj\".*\",\"$loglevel\""
   local hasMapping=0
   local result
   for item in ${JSON_DICT[@]}; do
      if [[ $item =~ $pattern_map_obj ]]; then
         hasMapping=1
         local loglevel_mapping=${item##$pattern_map_obj}

         IFS=',' read -ra mapping <<< "$loglevel_mapping"
         local standard_level=${mapping[0]}

         local mapped_levels=${loglevel_mapping##$standard_level,}
         mapped_levels=$(trim $mapped_levels)

         if contains_loglevel "$mapped_levels" "$loglevel"; then
            result+="$(trim $standard_level),"
         fi
      fi
   done

   if [ $hasMapping -eq 0 ]; then
      result=$(toupper $loglevel)
   elif [ $hasMapping -eq 1 ] && [ -z "$result" ]; then
      result=$LOGLEVEL_UNKNOWN
   fi

   # Remove the tail ','
   result=${result%,}
   result=$(toupper $result)

   echo $result
}


#----------------------------------------------------------------
#
# writeConfigToIniFile --
#
#    Write a config to an INI config file
#
#    Arguments:
#    1. path of config file
#    2. config key
#    3. config value
#
#----------------------------------------------------------------

function writeConfigToIniFile()
{
   local path=$1
   local key=$2
   local value=$3
   local dirpath=""

   # Remove the "" for the string
   path=$(trim "$path")
   path="${path/#~/$(get_home_dir $username)}"
   key=$(trim "$key")
   value=$(trim "$value")

   if ! [ -e $path ]; then
      dirpath=$(dirname "$path")
      if (! [ -e $dirpath ] && ! mkdir -p $dirpath 2>/dev/null) || ([ -e $dirpath ] && ! touch $path 2>/dev/null); then
         return 1
      fi
   fi

   if [ -w $path ]; then
      updateIniConfig $path $key $value
   fi
}


#----------------------------------------------------------------
#
# updateIniConfig --
#
#    Update a INI config value
#
#    Arguments:
#    1. path of config file
#    2. config key
#    3. config value
#
#----------------------------------------------------------------

function updateIniConfig()
{
   local path=$1
   local key=$2
   local value=$3
   local new_config="$key = $value"
   local config_pattern="^.*$key.*=.*$"

   grep -q "$config_pattern" $path

   # Update the current config or append new config
   if [ $? -eq 0 ]; then
      sed -i.bak "s/$config_pattern/$new_config/g" $path
   else
      appendIniConfig "$path" "$key" "$value"
   fi
}


#----------------------------------------------------------------
#
# deleteConfigFromIniFile --
#
#    Delete a config from an INI config file
#
#    Arguments:
#    1. path of config file
#    2. config key
#
#----------------------------------------------------------------

function deleteConfigFromIniFile()
{
   local path=$1
   local key=$2

   # Remove the "" for the string
   path=$(trim "$path")
   path="${path/#~/$(get_home_dir $username)}"
   key=$(trim "$key")

   if [ -e $path ] && [ -w $path ]; then
      deleteIniConfig $path $key
   fi
}


#----------------------------------------------------------------
#
# appendIniConfig --
#
#    Append a config to an INI config file
#
#    Arguments:
#    1. path of config file
#    2. config key
#    3. config value
#
#----------------------------------------------------------------

function appendIniConfig()
{
   local path=$1
   local key=$2
   local value=$3

   # Append config item to file
   echo "$key = $value" >> $path
}


#----------------------------------------------------------------
#
# deleteIniConfig --
#
#    Delete a INI config
#
#    Arguments:
#    1. path of config file
#    2. config key
#
#----------------------------------------------------------------

function deleteIniConfig()
{
   local path=$1
   local key=$2

   sed -i.bak "/^.*$key.*=.*$/d" $path
}


#----------------------------------------------------------------
#
# setEnvVar --
#
#    Set environment variable
#
#    Arguments:
#    1. name of environment variable
#    2. value of environment variable
#
#----------------------------------------------------------------

function setEnvVar()
{
   local var=$1
   local value=$2

   # Remove the "" for the string
   var=$(trim "$var")
   value=$(trim "$value")

   set_env_var $var $value
}


#----------------------------------------------------------------
#
# unsetEnvVar --
#
#    Unset environment variable
#
#    Arguments:
#    Name of environment variable
#
#----------------------------------------------------------------

function unsetEnvVar()
{
   local var=$(trim "$1")
   unset_env_var $var
}


#----------------------------------------------------------------
#
# initFileFilter --
#
#    Init file filter.
#
#    Filter options supported:
#    - latest (only collect log/dump for latest lanched client instance)
#
#    Arguments:
#    File filter option
#
#----------------------------------------------------------------

function initFileFilter()
{
   local filter_option=$(tolower "$1")

   if [ "$filter_option" == "$DCT_FILTER_LATEST" ]; then
      filter_type=$DCT_FILTER_LATEST
      local client_log=$(ls -t "$client_log_dir"/$client_log_glob | head -n 1)

      # Set filter time as create time of latest client log
      if [ -n "$client_log" ]; then
         local time_before=$(head -n 1 "$client_log" | sed -e 's/: horizon-client.*$//')
         filter_time_before=$(format_date_string "$time_before")
      fi
   fi
}


#----------------------------------------------------------------
#
# filterLatest --
#
#    Filter log/dump file, file with time before latest launched
#    client log is filtered out.
#
#    Arguments:
#    Log file
#
#    Returns:
#    0 if the file is filtered by rule, otherwise 1
#
#----------------------------------------------------------------

function filterLatest()
{
   local file="$1"
   local file_time=$(read_file_modified_time "$file")

   if [ $file_time -lt $filter_time_before ] ; then
      return 0
   fi

   return 1
}


#----------------------------------------------------------------
#
# filterFile --
#
#    Check if the log/dump file should be filtered based on filter rule
#
#    Arguments:
#    Log/dump file
#
#    Returns:
#    0 if the file is filtered by rule, otherwise 1
#
#----------------------------------------------------------------

function filterFile()
{
   local file="$1"
   local result=1

   # Collect latest log/dump (related to latest launch client instance)
   if [ "$filter_type" == "$DCT_FILTER_LATEST" ]; then
      filterLatest "$file"
      result=$?
   fi

   return $result
}


#----------------------------------------------------------------
#
# collect_data_by_plugin_config --
#
#    Collect logs and dumps for specific feature by the info
#    provided in its plugin JSON config file
#
#    Arguments:
#    1. Plugin JSON config file
#    2. Filter option
#
#----------------------------------------------------------------

function collect_data_by_plugin_config()
{
   local file="$1"
   local filter_option="$2"
   local plugin_name=$(getPluginName "$file")

   # Parse Json file for the specified feature
   parse_json < $file

   # Collect logs
   if [[ "${JSON_DICT[@]}" =~ $PATTERN_LOGCOLLECT_SRC ]]; then
      log_info "Gathering logs for feature $(getFeatureName) ($plugin_name) ..."
      collectData "$CFG_LOGCOLLECT" "$filter_option"
   fi

   # Collect dumps
   if [[ "${JSON_DICT[@]}" =~ $PATTERN_DUMPCOLLECT_SRC ]]; then
      log_info "Gathering dumps for feature $(getFeatureName) ($plugin_name) ..."
      collectData "$CFG_DUMPCOLLECT" "$filter_option"
   fi
}


#----------------------------------------------------------------
#
# collectData --
#
#    Collect logs or dumps from specified source folder with
#    rule defined to specified target folder (if exists)
#
#    Arguments:
#    1. Config for data type to collect (log/dump)
#    2. Filter option
#
#----------------------------------------------------------------

function collectData()
{
   local CFG_DATA_TYPE="$1"
   local filter_option="$2"
   local PATTERN_DATA_SRC
   local PATTERN_DATA_RULE
   local dest
   local pattern_tgtfolder
   local tgtfolder
   local print_permission_warning=0

   declare -a srcfolders
   declare -a rules

   if [ $CFG_DATA_TYPE == $CFG_LOGCOLLECT ]; then
      PATTERN_DATA_SRC=$PATTERN_LOGCOLLECT_SRC
      PATTERN_DATA_RULE=$PATTERN_LOGCOLLECT_RULE
   elif [ $CFG_DATA_TYPE == $CFG_DUMPCOLLECT ]; then
      PATTERN_DATA_SRC=$PATTERN_DUMPCOLLECT_SRC
      PATTERN_DATA_RULE=$PATTERN_DUMPCOLLECT_RULE
   fi

   for item in "${JSON_DICT[@]}"; do
      if [[ $item =~ $PATTERN_DATA_SRC ]]; then
         folder=${item##$PATTERN_DATA_SRC}
         srcfolders+=($folder)
      elif [[ $item =~ $PATTERN_DATA_RULE ]]; then
         rule=${item##$PATTERN_DATA_RULE}
         rules+=($rule)
      fi
   done

   for ((i=0; i < ${#srcfolders[@]}; i++)); do
      dest="$tmpdir/$targetDirectory"
      pattern_tgtfolder="\"$CFG_DATA_TYPE\",\"$CFG_PATHS\",$i,\"$CFG_TGT\","
      for item in ${JSON_DICT[@]}; do
         if [[ $item =~ $pattern_tgtfolder ]]; then
            tgtfolder=${item##$pattern_tgtfolder}
            tgtfolder=$(trim "$tgtfolder")
         fi
      done

      if [ ! -z "$tgtfolder" ]; then
         dest="$dest/$tgtfolder"
         tgtfolder=""
      fi
      if ! stageFiles "${srcfolders[$i]}" "${rules[$i]}" "$dest" "$filter_option"; then
         print_permission_warning=1
      fi
   done

   if [ $print_permission_warning -eq 1 ]; then
      log_error "Failed to collect some logs for $(getFeatureName), root permission is required, please use 'sudo <command>'"
   fi
}


#----------------------------------------------------------------
#
# stageFiles --
#
#    Find log/dump files that match collect rule in source directory,
#    and copy them to the temp diretory for DCT data collection
#
#    Arguments:
#    1. source directory
#    2. collect rule (e.g. horizon-*.log)
#    3. dest directory
#    4. filter option
#
#----------------------------------------------------------------

function stageFiles()
{
   local srcdir=$(trim "$1")
   local rule=$(trim "$2")
   local dest="$3"
   local filter_option="$4"
   local result=0

   declare -a srcdir_list

   # Handle path aliases
   srcdir="${srcdir/#~/$(get_home_dir $username)}"

   for path_alias in ${PATH_ALIAS_LIST[@]}; do
      if [[ "$srcdir" =~ "$path_alias" ]]; then
         # For Linux client, OMNISSA_TMP_DIR may includes multiple paths, so handle
         # the alias specifically
         if [ $path_alias == "OMNISSA_TMP_DIR" ]; then
            IFS=' ' read -a srcdir_list <<< $(get_expanded_temp_log_dir $srcdir)
         else
            srcdir=${srcdir//$path_alias/${!path_alias}}
            srcdir_list+=($srcdir)
         fi
         break
      fi
   done

   if [ ${#srcdir_list[@]} -eq 0 ]; then
      srcdir_list+=($srcdir)
   fi

   # Support collect data by filter
   initFileFilter "$filter_option"

   for dir in ${srcdir_list[@]}; do
      if ! copyFiles "$dir" "$rule" "$dest"; then
         result=1
      fi
   done

   return $result
}


#----------------------------------------------------------------
#
# copyFiles --
#
#    Copy files matching the rule to dest directory.
#
#    Arguments:
#    1. source directory
#    2. collect rule (e.g. horizon-*.log)
#    3. dest directory
#
#----------------------------------------------------------------

function copyFiles()
{
   local srcdir="$1"
   local rule="$2"
   local dest="$3"
   local result=0

   for file in $(ls -t "$srcdir"/$rule 2>/dev/null); do
      if filterFile "$file" ; then
         continue
      fi

      [ ! -e "$dest" ] && mkdir -p "$dest" 2>/dev/null

      [ -e "$dest/$(basename $file)" ] && continue

      if ! cp -p "$file" "$dest" 2>/dev/null ; then
         log_debug "Unable to copy file $file to $dest."
         result=1
      else
         log_debug "Copy file $file."
      fi
   done

   return $result
}


#----------------------------------------------------------------
#
# collectDCTLogs --
#
#    Collect log files for DCT script
#
#----------------------------------------------------------------

function collectDCTLogs()
{
   local dest="$tmpdir/$targetDirectory"
   local dct_log_dir=$(get_dct_log_dir)
   local dct_log_glob="$dct_log_dir/horizon-dct-*.log"
   local latest_dct_log

   latest_dct_log=`ls -dt $dct_log_glob 2>/dev/null | head -n 1`

   [ -z "$latest_dct_log" ] && return

   if ! cp -p "$latest_dct_log" "$dest" 2>/dev/null ; then
      log_error "Unable to copy log file $file to $dest."
   fi
}


#----------------------------------------------------------------
#
# isValidLoglevel --
#
#    Check if the loglevel config has valid value
#    (INFO/DEBUG/TRACE/VERBOSE).
#
#    Arguments:
#    Log level config
#
#----------------------------------------------------------------

function isValidLoglevel()
{
   local value=$(toupper $1)

   for i in "${DCT_LOG_LEVELS[@]}"; do
      if [ "$i" == "$value" ]; then
         return 0
      fi
   done

   return 1
}
