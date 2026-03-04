#!/bin/bash
#
# Copyright (c) 2020 Omnissa, LLC. All rights reserved.
# This product is protected by copyright and intellectual property laws in the
# United States and other countries as well as by international treaties.
# -- Omnissa Public
#
# Horizon DCT script
#

SET_LOGLEVEL=0
QUERY_LOGLEVEL=0
COLLECT_DATA=1
RESET_LOGLEVEL=0
DCT_PATH=$(cd "$(dirname "$0")";pwd)
CONFIG_PATH="$DCT_PATH/configFiles"

source "$DCT_PATH/dct-command.sh"

parse_options "$@"

# Query log level for feature/components
if [ $QUERY_LOGLEVEL == 1 ]; then
   query_loglevel "$arguments" $QUERY_DETAIL
   exit 0
# Set log level for feature/components
elif [ $SET_LOGLEVEL == 1 ] || [ $RESET_LOGLEVEL == 1 ]; then
   set_loglevel
   exit 0
# Collect logs and dumps
else
   collect_data "$arguments"
fi

exit 0
