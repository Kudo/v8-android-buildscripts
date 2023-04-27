#!/bin/bash -e
source $(dirname $0)/env.sh

function makeDistPackageDir() {
  if [[ ${TOOLS_ONLY} = "true" ]]; then
    echo "${DIST_DIR}/packages/v8-android-tools"
    return 0
  fi

  local jit_suffix=""
  local intl_suffix=""
  if [[ ${NO_JIT} != "true" ]]; then
    jit_suffix="-jit"
  fi

  if [[ ${NO_INTL} = "true" ]]; then
    intl_suffix="-nointl"
  fi

  echo "${DIST_DIR}/packages/v8-${PLATFORM}${jit_suffix}${intl_suffix}"
}

DIST_PACKAGE_DIR=$(makeDistPackageDir)
mkdir -p "${DIST_PACKAGE_DIR}"

function createAAR() {
  printf "\n\n\t\t===================== create aar =====================\n\n"
  pushd .
  cd "${ROOT_DIR}/lib"
  ./gradlew clean :v8-android:createAAR --project-prop distDir="$DIST_PACKAGE_DIR" --project-prop version="$VERSION"
  popd
}

function createXcframework() {
  plist=$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>v8</string>
  <key>CFBundleIdentifier</key>
  <string>io.csie.kudo.v8.framework</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleSignature</key>
  <string>????</string>
</dict>
</plist>
EOF
)
  printf "\n\n\t\t===================== create ios device framework =====================\n\n"
  mkdir -p "${BUILD_DIR}/ios-arm64/v8.framework"
  echo "${plist}" > "${BUILD_DIR}/ios-arm64/v8.framework/Info.plist"
  cp -f "${BUILD_DIR}/lib/device/arm64/libv8.dylib" "${BUILD_DIR}/ios-arm64/v8.framework/v8"
  install_name_tool -id "@rpath/v8.framework/v8" "${BUILD_DIR}/ios-arm64/v8.framework/v8"

  printf "\n\n\t\t===================== create ios simulator framework =====================\n\n"
  mkdir -p "${BUILD_DIR}/ios-arm64_x86_64-simulator/v8.framework"
  echo "${plist}" > "${BUILD_DIR}/ios-arm64_x86_64-simulator/v8.framework/Info.plist"
  lipo "${BUILD_DIR}/lib/simulator/arm64/libv8.dylib" "${BUILD_DIR}/lib/simulator/x64/libv8.dylib" -output "${BUILD_DIR}/ios-arm64_x86_64-simulator/v8.framework/v8" -create
  install_name_tool -id "@rpath/v8.framework/v8" "${BUILD_DIR}/ios-arm64_x86_64-simulator/v8.framework/v8"

  printf "\n\n\t\t===================== create ios xcframework =====================\n\n"
  rm -rf "${BUILD_DIR}/v8.xcframework"
  xcodebuild -create-xcframework -framework "${BUILD_DIR}/ios-arm64/v8.framework" -framework "${BUILD_DIR}/ios-arm64_x86_64-simulator/v8.framework" -output "${BUILD_DIR}/v8.xcframework"

  cp -Rf "${BUILD_DIR}/v8.xcframework" "${DIST_PACKAGE_DIR}/v8.xcframework"
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
  cp -Rf "${BUILD_DIR}/tools" "${DIST_PACKAGE_DIR}/"
}

function copySnapshotBlobIfNeeded() {
  if [[ ${EXTERNAL_STARTUP_DATA} = "true" || ${TOOLS_ONLY} = "true" ]]; then
    printf "\n\n\t\t===================== adding snapshot_blob to ${DIST_PACKAGE_DIR}/snapshot_blob =====================\n\n"
    cp -Rf "${BUILD_DIR}/snapshot_blob" "${DIST_PACKAGE_DIR}/"
  fi
}


if [[ ${TOOLS_ONLY} = "true" ]]; then
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
  copySnapshotBlobIfNeeded
elif [[ ${PLATFORM} = "ios" ]]; then
  createXcframework
  copyHeaders
  copyTools
  copySnapshotBlobIfNeeded
fi
