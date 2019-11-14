#!/bin/bash -e
source $(dirname $0)/env.sh

######################################################################################
# Patchset management that manage files by commented purpose
######################################################################################
V8_PATCHSET_ANDROID=(
  # V8 shared library support
  "v8_shared_library.patch"
)

V8_PATCHSET_IOS=(
  # V8 shared library support
  "v8_shared_library_ios.patch"
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

if [[ ${PLATFORM} = "android" ]]; then
  for patch in "${V8_PATCHSET_ANDROID[@]}"
  do
    printf "### Patch set: ${patch}\n"
    patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/$patch"
  done

  setupNDK
elif [[ ${PLATFORM} = "ios" ]]; then
  for patch in "${V8_PATCHSET_IOS[@]}"
  do
    printf "### Patch set: ${patch}\n"
    patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/$patch"
  done
fi
