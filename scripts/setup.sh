#!/bin/bash -e
source $(dirname $0)/env.sh

GCLIENT_SYNC_ARGS="--reset --with_branch_head"
while getopts 'r:s' opt; do
    case ${opt} in
        r)
            GCLIENT_SYNC_ARGS+=" --revision $OPTARG"
            ;;
        s)
            GCLIENT_SYNC_ARGS+=" --no-history"
            ;;
    esac
done


if [[ ! -d "$DEPOT_TOOLS_DIR" || ! -f "$DEPOT_TOOLS_DIR/gclient" ]]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_DIR
fi

gclient config --name v8 --unmanaged "https://chromium.googlesource.com/v8/v8.git"
gclient sync --deps=android $GCLIENT_SYNC_ARGS
sudo bash -c 'v8/build/install-build-deps-android.sh'

# Workaround to install missing sysroot
gclient sync

# Install NDK
function installNDK() {
  version=$1
  pushd .
  cd $V8_DIR
  wget -q https://dl.google.com/android/repository/android-ndk-${version}-linux-x86_64.zip
  unzip -q android-ndk-${version}-linux-x86_64.zip
  rm -f android-ndk-${version}-linux-x86_64.zip

  echo "default_android_ndk_root = \"//android-ndk-${version}\"" >> $V8_DIR/build_overrides/build.gni
  echo "default_android_ndk_version = \"${version}\"" >> $V8_DIR/build_overrides/build.gni
  ndk_major_version=`echo "${version//[^0-9.]/}"`
  echo "default_android_ndk_major_version = ${ndk_major_version}" >> $V8_DIR/build_overrides/build.gni

  unset ndk_major_version
  unset version
  popd
}

installNDK "r17c"
