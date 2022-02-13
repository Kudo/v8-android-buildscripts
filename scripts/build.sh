#!/bin/bash -e
source $(dirname $0)/env.sh
BUILD_TYPE="Release"
# BUILD_TYPE="Debug"

# $1 is ${PLATFORM} which parse commonly from env.sh
ARCH=$2

GN_ARGS_BASE="
  target_os=\"${PLATFORM}\"
  is_component_build=false
  use_custom_libcxx=false
  icu_use_data_file=false
"

if [[ ${PLATFORM} = "ios" ]]; then
  GN_ARGS_BASE="${GN_ARGS_BASE} enable_ios_bitcode=false use_xcode_clang=true ios_enable_code_signing=false v8_enable_pointer_compression=false ios_deployment_target=${IOS_DEPLOYMENT_TARGET}"
fi

if [[ ${NO_INTL} = "true" ]]; then
  GN_ARGS_BASE="${GN_ARGS_BASE} v8_enable_i18n_support=false"
fi

if [[ ${NO_JIT} = "true" ]]; then
  GN_ARGS_BASE="${GN_ARGS_BASE} v8_enable_lite_mode=true"
fi

if [[ ${EXTERNAL_STARTUP_DATA} = "true" || ${MKSNAPSHOT_ONLY} = 1 ]]; then
  GN_ARGS_BASE="${GN_ARGS_BASE} v8_use_external_startup_data=true"
else
  GN_ARGS_BASE="${GN_ARGS_BASE} v8_use_external_startup_data=false"
fi

if [[ "$BUILD_TYPE" = "Debug" ]]
then
  GN_ARGS_BUILD_TYPE='
    is_debug=true
    symbol_level=2
  '
else
  GN_ARGS_BUILD_TYPE='
    is_debug=false
  '
fi

NINJA_PARAMS=""

if [[ ${CIRCLECI} ]]; then
  NINJA_PARAMS="-j4"
fi

cd ${V8_DIR}

function normalize_arch_for_platform()
{
  local arch=$1

  if [[ ${PLATFORM} = "ios" ]]; then
    echo ${arch}
    return
  fi

  case "$1" in
    arm)
      echo "armeabi-v7a"
      ;;
    x86)
      echo "x86"
      ;;
    arm64)
      echo "arm64-v8a"
      ;;
    x64)
      echo "x86_64"
      ;;
    *)
      echo "Invalid arch - ${arch}" >&2
      exit 1
      ;;
  esac
}

function build_arch()
{
  local arch=$1
  local platform_arch=$(normalize_arch_for_platform $arch)

  local target=''
  local target_ext=''
  if [[ ${PLATFORM} = "android" ]]; then
    target="libv8android"
    target_ext=".so"
  elif [[ ${PLATFORM} = "ios" ]]; then
    target="libv8"
    target_ext=".dylib"
  else
    exit 1
  fi

  echo "Build v8 ${arch} variant NO_INTL=${NO_INTL} NO_JIT=${NO_JIT}"
  gn gen --args="${GN_ARGS_BASE} ${GN_ARGS_BUILD_TYPE} target_cpu=\"${arch}\"" "out.v8.${arch}"

  if [[ ${MKSNAPSHOT_ONLY} = "1" ]]; then
    date ; ninja ${NINJA_PARAMS} -C "out.v8.${arch}" run_mksnapshot_default mkcodecache_group ; date
  else
    date ; ninja ${NINJA_PARAMS} -C "out.v8.${arch}" ${target} run_mksnapshot_default ; date

    mkdir -p "${BUILD_DIR}/lib/${platform_arch}"
    cp -f "out.v8.${arch}/${target}${target_ext}" "${BUILD_DIR}/lib/${platform_arch}/${target}${target_ext}"

    if [[ -d "out.v8.${arch}/lib.unstripped" ]]; then
      mkdir -p "${BUILD_DIR}/lib.unstripped/${platform_arch}"
      cp -f "out.v8.${arch}/lib.unstripped/${target}${target_ext}" "${BUILD_DIR}/lib.unstripped/${platform_arch}/${target}${target_ext}"
    fi
  fi

  mkdir -p "${BUILD_DIR}/tools/${platform_arch}"
  cp -f out.v8.${arch}/clang_*/mksnapshot "${BUILD_DIR}/tools/${platform_arch}/mksnapshot"

  if [[ ${MKSNAPSHOT_ONLY} = "1" ]]; then
    cp -f out.v8.${arch}/clang_*/mkcodecache "${BUILD_DIR}/tools/${platform_arch}/mkcodecache"
  fi

  if [[ ${EXTERNAL_STARTUP_DATA} = "true" || ${MKSNAPSHOT_ONLY} = 1 ]]; then
    mkdir -p "${BUILD_DIR}/snapshot_blob/${platform_arch}"
    cp -f out.v8.${arch}/snapshot_blob.bin "${BUILD_DIR}/snapshot_blob/${platform_arch}/snapshot_blob.bin"
  fi
}

if [[ ${ARCH} ]]; then
  build_arch "${ARCH}"
elif [[ ${PLATFORM} = "android" ]]; then
  build_arch "arm"
  build_arch "x86"
  build_arch "arm64"
  build_arch "x64"
elif [[ ${PLATFORM} = "ios" ]]; then
  build_arch "arm64"
  build_arch "x64"
fi
