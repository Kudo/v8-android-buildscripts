#!/bin/bash -e
source $(dirname $0)/env.sh

function makeDistPackageDir() {
  if [[ ${MKSNAPSHOT_ONLY} = "1" ]]; then
    echo "${DIST_DIR}/packages/v8-${PLATFORM}-tools"
    return 0
  fi

  local jit_suffix=""
  local intl_suffix=""
  if [[ ${NO_JIT} != "0" ]]; then
    jit_suffix="-jit"
  fi

  if [[ ${NO_INTL} = "1" ]]; then
    intl_suffix="-nointl"
  fi

  echo "${DIST_DIR}/packages/v8-${PLATFORM}${jit_suffix}${intl_suffix}"
}

DIST_PACKAGE_DIR=$(makeDistPackageDir)

function createAAR() {
  printf "\n\n\t\t===================== create aar =====================\n\n"
  pushd .
  cd "${ROOT_DIR}/lib"
  ./gradlew clean :v8-android:createAAR --project-prop distDir="$DIST_PACKAGE_DIR" --project-prop version="$VERSION"
  popd
}

function createUniversalDylib() {
  printf "\n\n\t\t===================== create universal dylib =====================\n\n"
  mkdir -p "${BUILD_DIR}/lib/universal"
  lipo "${BUILD_DIR}/lib/arm64/libv8.dylib" "${BUILD_DIR}/lib/x64/libv8.dylib" -output "${BUILD_DIR}/lib/universal/libv8.dylib" -create
}

function copyDylib() {
  printf "\n\n\t\t===================== copy dylib =====================\n\n"
  mkdir -p "${DIST_PACKAGE_DIR}"
  cp -Rf "${BUILD_DIR}/lib" "${DIST_PACKAGE_DIR}/"
}

function createUnstrippedLibs() {
  printf "\n\n\t\t===================== create unstripped libs =====================\n\n"
  DIST_LIB_UNSTRIPPED_DIR="${DIST_PACKAGE_DIR}/lib.unstripped/v8-${PLATFORM}/${VERSION}"
  mkdir -p "${DIST_LIB_UNSTRIPPED_DIR}"
  tar cfJ "${DIST_LIB_UNSTRIPPED_DIR}/libs.tar.xz" -C "${BUILD_DIR}/lib.unstripped" .
  unset DIST_LIB_UNSTRIPPED_DIR
}

function copyHeaders() {
  printf "\n\n\t\t===================== adding headers to ${DIST_PACKAGE_DIR}/include =====================\n\n"
  cp -Rf "${V8_DIR}/include" "${DIST_PACKAGE_DIR}/include"
}

function copyTools() {
  printf "\n\n\t\t===================== adding tools to ${DIST_PACKAGE_DIR}/tools =====================\n\n"
  cp -Rf "${BUILD_DIR}/tools" "${DIST_PACKAGE_DIR}/tools"
}


if [[ ${MKSNAPSHOT_ONLY} = "1" ]]; then
  mkdir -p "$DIST_PACKAGE_DIR"
  copyTools
  exit 0
fi

if [[ ${PLATFORM} = "android" ]]; then
  export ANDROID_HOME="${V8_DIR}/third_party/android_sdk/public"
  export ANDROID_NDK="${V8_DIR}/third_party/android_ndk"
  export PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}
  yes | sdkmanager --licenses

  mkdir -p "${DIST_PACKAGE_DIR}"
  createAAR
  createUnstrippedLibs
  copyHeaders
  copyTools
elif [[ ${PLATFORM} = "ios" ]]; then
  createUniversalDylib
  copyDylib
  copyHeaders
  copyTools
fi
