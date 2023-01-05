#!/bin/bash -e
source $(dirname $0)/env.sh

######################################################################################
# Patchset management that manage files by commented purpose
######################################################################################
V8_PATCHSET_ANDROID=(
  # V8 shared library support
  "v8_shared_library.patch"

  # https://github.com/Kudo/react-native-v8/issues/27
  "workaround_jsi_object_freeze.patch"

  # Support to specify custom timezone
  # https://github.com/Kudo/react-native-v8/issues/37
  "custom_timezone.patch"

  # Fix v8 9.7 build error
  "v8_97_android_build_error.patch"

  # Fix v8 9.7 libunwind link error
  # revert https://chromium.googlesource.com/chromium/src/build/+/7bb5f36104
  # "v8_97_android_unwind_link_error.patch"

  # Add mkcodecache tool
  "mkcodecache.patch"

  # Fix for [react-native-bottom-sheet](https://github.com/gorhom/react-native-bottom-sheet) not working
  # revert https://chromium-review.googlesource.com/c/v8/v8/+/3548458
  "fix_for_bottom_sheet.patch"
)

V8_PATCHSET_IOS=(
  # V8 shared library support
  "v8_shared_library_ios.patch"

  # https://github.com/Kudo/react-native-v8/issues/27
  "workaround_jsi_object_freeze.patch"

  # Workaround latest Xcode12 build break on non Apple Silicon
  # "v8_ios_host_break.patch"

  # Fix use_system_xcode build error
  "system_xcode_build_error.patch"

  # Add mkcodecache tool
  "mkcodecache.patch"

  # Fix for [react-native-bottom-sheet](https://github.com/gorhom/react-native-bottom-sheet) not working
  # revert https://chromium-review.googlesource.com/c/v8/v8/+/3548458
  "fix_for_bottom_sheet.patch"
)

V8_PATCHSET_MACOS_ANDROID=(
  # Add mkcodecache tool
  "mkcodecache.patch"
)

######################################################################################
# Patchset management end
######################################################################################

#
# Setup custom NDK for v8 build
#
function setupNDK() {
  echo "default_android_ndk_root = \"//android-ndk-${NDK_VERSION}\"" >> ${V8_DIR}/build_overrides/build.gni
  echo "default_android_ndk_version = \"${NDK_VERSION}\"" >> ${V8_DIR}/build_overrides/build.gni
  ndk_major_version=`echo "${NDK_VERSION//[^0-9.]/}"`
  echo "default_android_ndk_major_version = ${ndk_major_version}" >> ${V8_DIR}/build_overrides/build.gni
  unset ndk_major_version
}

function setupMkCodecache() {
  mkdir -p "${V8_DIR}/src/mkcodecache"
  cp -f "${ROOT_DIR}/mkcodecache/mkcodecache.cc" "${V8_DIR}/src/mkcodecache/"
}

if [[ ${PLATFORM} = "android" ]]; then
  for patch in "${V8_PATCHSET_ANDROID[@]}"
  do
    printf "### Patch set: ${patch}\n"
    patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/$patch"
  done

  setupNDK
  setupMkCodecache
elif [[ ${PLATFORM} = "ios" ]]; then
  for patch in "${V8_PATCHSET_IOS[@]}"
  do
    printf "### Patch set: ${patch}\n"
    patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/$patch"
  done

  setupMkCodecache
elif [[ ${PLATFORM} = "macos_android" ]]; then
  for patch in "${V8_PATCHSET_MACOS_ANDROID[@]}"
  do
    printf "### Patch set: ${patch}\n"
    patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/$patch"
  done

  setupNDK
  setupMkCodecache
fi
