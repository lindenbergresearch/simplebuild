#!/bin/bash
#
# SIMPLE BUILD FOR RACK
#
# main build script
#
# Copyright 2017 Lindenberg Research Tec.
# All rights MIT licenced.
#
# DATE      : 11/07/2017
# AUTHOR    : patrick@heapdump.com
#

#
# global parameter
#
SCRIPT_FILE=$0
PARAM=$1
BASEDIR="."

TITLE="Simple Build for Rack"
VERSION="0.0.1"
VENDOR="http://github.com/lindenbergresearch"

TARGETS_CONFIG="targets.build"
TARGET_PREFIX="target_"
INIT_FUNCTION="startup"

RACK_DIR=""
DEFAULT_TARGET=""


#
# check if given target exists
#
target_exists() {
  # use prefixed underscores to define a target as bash function
  local TARGET_FUNCTION=${TARGET_PREFIX}${1}
  [ `type -t ${TARGET_FUNCTION}`"" == 'function' ]
}


#
# print usage text
#
function print_usage() {
	printf "Usage Info: build [target]\n\n"
	printf "	all		build Rack and plugin\n"
	printf "	plugin	build plugin only\n"
	printf "	run		build plugin and run rack\n\n"
	printf "	-		build default target: $DEFAULT_TARGET\n"
}


#
# abort build script due to raised error
#
function abort() {
	local MSG=$1
	local EC=$2

    printf "\e[31m"
	printf "\n\a[BUILD ABORTED: $1]\n\n"
    printf "\e[39m"

	# if exit code passed => exit
	[[ ${EC} != "" ]] && exit ${EC}
}


#
# test file for symbolic link
#
function islinked() {
    readlink $1 > /dev/null
    return $?
}


#
# run target and check for error
#
function run() {
	local TARGET=$1
	# add prefix to target name to get function binding
	local FUNCTION_NAME=${TARGET_PREFIX}${TARGET}

	# check if target name given and valid
	[[ ${TARGET} == "" ]] && abort "run can not execute an empty target" 6

	printf "\e[96m"
	printf "\n[$TARGET]\n"
	printf "\e[39m"

	${FUNCTION_NAME} | sed "s/^/    /"
	local RESULT=$?

	# check success of executed target
	[[ ${RESULT} != 0 ]] && abort "Target: '$TARGET' aborted with exit-code: $RESULT"
}


#
# init build process
#
function init() {

    # check for base directory of current script
    # this is a bit tricky... don't forget symbolic links!
    if islinked ${SCRIPT_FILE}; then
        local TMP=$(readlink ${SCRIPT_FILE})
        BASEDIR=$(dirname ${TMP})
    else
        BASEDIR=$(dirname ${SCRIPT_FILE})
    fi

    # pull qualified path to target definition
    local INCLUDE_FILE=${BASEDIR}/${TARGETS_CONFIG}

	# check if target definition exists
	[[ -f ${INCLUDE_FILE} ]] || abort "Target definition file not found: '$INCLUDE_FILE'"

	# load target definitions into current shell
	. ${INCLUDE_FILE}

	# check for default target
	target_exists ${DEFAULT_TARGET} || abort "Default target does not exist: '${DEFAULT_TARGET}'" 3
	
	# check for Rack dir
	[[ -d ${RACK_DIR} ]] || abort "Rack base directory does not exist: '$RACK_DIR'" 4

    # execute init project specific routine
    if [ `type -t ${INIT_FUNCTION}`"" == 'function' ]; then
        printf "\e[96m"
        printf "[${INIT_FUNCTION}]\n"
	    printf "\e[39m"

        # run init routine from target definition
        ${INIT_FUNCTION} | sed "s/^/    /"
        local RESULT=$?

        # check success of init routine
        [[ ${RESULT} != 0 ]] && abort "Init routine aborted with exit-code: $RESULT"
    fi
}

#
# build target
#
function build() {
	# empty parameter => run default target
	[[ ${PARAM} == "" ]] && run ${DEFAULT_TARGET} ; return


}

printf "\e[97m"

# print app info
printf "\n$TITLE $VERSION\n"
printf "$VENDOR\n"
printf "All rights MIT licensed.\n\n"

printf "\e[39m"

# capture current time for build measurement
START_TIME=$(date +%s)

init
build

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))"s"

printf "\n[BUILD FINISHED in $TOTAL_TIME]\n\n"