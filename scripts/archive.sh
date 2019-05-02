#!/bin/bash -e
source $(dirname $0)/env.sh

function createAAR() {
  printf "\n\n\t\t===================== create aar :$TARGET: =====================\n\n"
  pushd .
  cd $ROOT_DIR/lib
  ./gradlew clean :v8-android:createAAR --project-prop distDist="$DIST_DIR" --project-prop version="$VERSION"
  popd
}

function createUnstrippedLibs() {
  printf "\n\n\t\t===================== create unstripped libs =====================\n\n"
  DIST_LIB_UNSTRIPPED_DIR="$DIST_DIR/lib.unstripped/v8-android/$VERSION"
  mkdir -p $DIST_LIB_UNSTRIPPED_DIR
  tar cfJ $DIST_LIB_UNSTRIPPED_DIR/libs.tar.xz -C $BUILD_DIR/lib.unstripped .
  unset DIST_LIB_UNSTRIPPED_DIR
}

function copyHeaders() {
  printf "\n\n\t\t===================== adding headers to $DIST_DIR/include =====================\n\n"
  cp -Rf $V8_DIR/include $DIST_DIR/include
}

export ANDROID_HOME="$V8_DIR/third_party/android_tools/sdk"
export ANDROID_NDK="$V8_DIR/third_party/android_ndk"

mkdir -p $DIST_DIR
createAAR
createUnstrippedLibs
copyHeaders
