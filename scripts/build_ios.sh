#!/bin/bash -e
source $(dirname $0)/env.sh
BUILD_TYPE="Release"
# BUILD_TYPE="Debug"

GN_ARGS_BASE='
  target_os="ios"
  is_component_build=false
  use_debug_fission=false
  use_custom_libcxx=false
  v8_use_snapshot=true
  v8_use_external_startup_data=false
  icu_use_data_file=false
  v8_enable_lite_mode=true
  enable_ios_bitcode=false
  ios_deployment_target=9
  use_xcode_clang=true
'

if [[ ${NO_INTL} -eq "1" ]]; then
  GN_ARGS_BASE="${GN_ARGS_BASE} v8_enable_i18n_support=false"
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

cd $V8_DIR

function build_arch()
{
    local arch=$1

    echo "Build v8 $arch variant NO_INTL=${NO_INTL}"
    gn gen --args="$GN_ARGS_BASE $GN_ARGS_BUILD_TYPE target_cpu=\"$arch\"" out.v8.$arch

    if [[ ${MKSNAPSHOT_ONLY} -eq "1" ]]; then
      date ; ninja ${NINJA_PARAMS} -C out.v8.$arch run_mksnapshot_default ; date
    else
      date ; ninja ${NINJA_PARAMS} -C out.v8.$arch libv8 ; date

      mkdir -p $BUILD_DIR/lib/$arch
      cp -f out.v8.$arch/libv8.dylib $BUILD_DIR/lib/$arch/libv8.dylib
      mkdir -p $BUILD_DIR/lib.unstripped/$arch
      cp -f out.v8.$arch/lib.unstripped/libv8.dylib $BUILD_DIR/lib.unstripped/$arch/libv8.dylib
    fi

    mkdir -p $BUILD_DIR/tools/$arch
    cp -f out.v8.$arch/clang_*/mksnapshot $BUILD_DIR/tools/$arch/mksnapshot
}

# build_arch "arm64"
build_arch "x64"
