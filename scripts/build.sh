#!/bin/bash -e
source $(dirname $0)/env.sh
BUILD_TYPE="Release"
# BUILD_TYPE="Debug"

GN_ARGS_BASE='
  target_os="android"
  is_component_build=false
  use_debug_fission=false
  v8_expose_symbols=true
'

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

cd $V8_DIR

function build_arch()
{
    arch=$1
    echo "Build v8 $arch variant"
    if [[ "$arch" = "arm64" ]]; then
        # V8 mksnapshot will have alignment exception for lite mode, workaround to turn it off.
        gn gen --args="$GN_ARGS_BASE $GN_ARGS_BUILD_TYPE target_cpu=\"$arch\" v8_enable_lite_mode=false" out.v8.$arch
    else
        gn gen --args="$GN_ARGS_BASE $GN_ARGS_BUILD_TYPE target_cpu=\"$arch\" v8_enable_lite_mode=true" out.v8.$arch
    fi
    date ; ninja -j4 -C out.v8.$arch libv8 ; date
    mkdir -p $BUILD_DIR/lib/$arch
    cp -f out.v8.$arch/libv8.so $BUILD_DIR/lib/$arch/libv8.so
    mkdir -p $BUILD_DIR/lib.unstripped/$arch
    cp -f out.v8.$arch/lib.unstripped/libv8.so $BUILD_DIR/lib.unstripped/$arch/libv8.so
    unset arch
}

build_arch "arm"
build_arch "x86"
build_arch "arm64"
build_arch "x64"
