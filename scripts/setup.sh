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
  wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-${host_arch}.zip
  unzip -q android-ndk-${NDK_VERSION}-${host_arch}.zip
  rm -f android-ndk-${NDK_VERSION}-${host_arch}.zip
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
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS} || true
  sed -i "s#2c2138e811487b13020eb331482fb991fd399d4e#083aa67a0d3309ebe37eafbe7bfd96c235a019cf#g" v8/DEPS
  gclient sync --deps=android

  # Patch build-deps installer for snapd not available in docker
  echo "ooxx setup patch prebuild_no_snapd"
  patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/prebuild_no_snapd.patch"

  echo "ooxx install-build-deps-android"
  sudo bash -c 'v8/build/install-build-deps-android.sh'
  echo "ooxx install apt-get"
  sudo apt-get -y install \
      libc6-dev \
      libc6-dev-i386 \
      libc6-dev-armel-cross \
      libc6-dev-armhf-cross \
      libc6-dev-arm64-cross \
      libc6-dev-armel-armhf-cross \
      libgcc-10-dev-armhf-cross \
      libstdc++-9-dev \
      lib32stdc++-9-dev \
      libx32stdc++-9-dev \
      libstdc++-10-dev-armhf-cross \
      libstdc++-9-dev-armhf-cross \
      libsfstdc++-10-dev-armhf-cross

  # Reset changes after installation
  echo "ooxx setup revert prebuild_no_snapd"
  patch -d "${V8_DIR}" -p1 -R < "${PATCHES_DIR}/prebuild_no_snapd.patch"

  # Workaround to install missing sysroot
  echo "ooxx gclient sync#1"
  gclient sync

  # Workaround to install missing android_sdk tools
  echo "ooxx gclient sync#2"
  gclient sync --deps=android

  echo "ooxx install ndk"
  installNDK "linux"
  exit 0
fi

if [[ ${PLATFORM} = "macos_android" ]]; then
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS} || true
  sed -i "" "s#2c2138e811487b13020eb331482fb991fd399d4e#083aa67a0d3309ebe37eafbe7bfd96c235a019cf#g" v8/DEPS
  gclient sync --deps=android

  installNDK "darwin"
  exit 0
fi
