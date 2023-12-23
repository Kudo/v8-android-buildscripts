#!/bin/bash -e

function abs_path()
{
  readlink="readlink -f"
  if [[ "$(uname)" == "Darwin" ]]; then
    if [[ ! "$(command -v greadlink)" ]]; then
      echo "greadlink not found. Please install greadlink by \`brew install coreutils\`" >&2
      exit 1
    fi
    readlink="greadlink -f"
  fi

  echo `$readlink $1`
}

function verify_platform()
{
  local arg=$1
  SUPPORTED_PLATFORMS=(android ios macos_android)
  local valid_platform=
  for platform in ${SUPPORTED_PLATFORMS[@]}
  do
    if [[ ${arg} = ${platform} ]]; then
      valid_platform=${platform}
    fi
  done
  if [[ -z ${valid_platform} ]]; then
    echo "Invalid platfrom: ${arg}" >&2
    exit 1
  fi
  echo ${valid_platform}
}

CURR_DIR=$(dirname $(abs_path $0))
ROOT_DIR=$(dirname ${CURR_DIR})
unset CURR_DIR

DEPOT_TOOLS_DIR="${ROOT_DIR}/scripts/depot_tools"
BUILD_DIR="${ROOT_DIR}/build"
V8_DIR="${ROOT_DIR}/v8"
DIST_DIR="${ROOT_DIR}/dist"
PATCHES_DIR="${ROOT_DIR}/patches"

NDK_VERSION="r23c"
IOS_DEPLOYMENT_TARGET="12.0"

export PATH="$DEPOT_TOOLS_DIR:$PATH"
PLATFORM=$(verify_platform $1)

if [[ -z ${EXTERNAL_STARTUP_DATA} ]]; then
  if [[ ${PLATFORM} = "android" ]]; then
    EXTERNAL_STARTUP_DATA="true"
  else
    EXTERNAL_STARTUP_DATA="false"
  fi
fi
if [[ -z ${NO_JIT} && ${PLATFORM} = "ios" ]]; then
  NO_JIT="true"
fi
