#!/bin/bash -e

GCLIENT_SYNC_ARGS="--reset --with_branch_head"
while getopts 'r:s' opt; do
  case ${opt} in
    r)
      GCLIENT_SYNC_ARGS+=" --revision ${OPTARG}"
      ;;
    s)
      GCLIENT_SYNC_ARGS+=" --no-history"
      ;;
  esac
done
shift $(expr ${OPTIND} - 1)

source $(dirname $0)/env.sh

# Install NDK
function installNDK() {
  local host_arch=$1
  pushd .
  cd "${V8_DIR}"
  wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-${host_arch}-x86_64.zip
  unzip -q android-ndk-${NDK_VERSION}-${host_arch}-x86_64.zip
  rm -f android-ndk-${NDK_VERSION}-${host_arch}-x86_64.zip
  popd
}

if [[ ! -d "${DEPOT_TOOLS_DIR}" || ! -f "${DEPOT_TOOLS_DIR}/gclient" ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
fi

gclient config --name v8 --unmanaged "https://chromium.googlesource.com/v8/v8.git"

if [[ ${PLATFORM} = "ios" ]]; then
  gclient sync --deps=ios ${GCLIENT_SYNC_ARGS}
  exit 0
fi

if [[ ${PLATFORM} = "android" ]]; then
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS}

  # Patch build-deps installer for snapd not available in docker
  patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/prebuild_no_snapd.patch"

  sudo bash -c 'v8/build/install-build-deps-android.sh'
  sudo apt-get -y install libgcc-10-dev-armhf-cross libc6-dev libc6-dev-armel-cross libc6-dev-armhf-cross libc6-dev-arm64-cross libc6-dev-i386 libc6-dev-armel-armhf-cross libstdc++-10-dev-armhf-cross

  # Reset changes after installation
  patch -d "${V8_DIR}" -p1 -R < "${PATCHES_DIR}/prebuild_no_snapd.patch"

  # Workaround to install missing sysroot
  gclient sync

  # Workaround to install missing android_sdk tools
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS}

  installNDK "linux"
  exit 0
fi

if [[ ${PLATFORM} = "macos_android" ]]; then
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS}
  installNDK "darwin"
  exit 0
fi
