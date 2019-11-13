#!/bin/bash -e
source $(dirname $0)/env.sh

DIST_PACKAGE_DIR="${DIST_DIR}/packages/v8-ios"
if [[ ${NO_INTL} -eq "1" ]]; then
  DIST_PACKAGE_DIR="${DIST_DIR}/packages/v8-ios-nointl"
elif [[ ${MKSNAPSHOT_ONLY} -eq "1" ]]; then
  DIST_PACKAGE_DIR="${DIST_DIR}/packages/v8-ios-tools"
fi


function copyLib() {
  printf "\n\n\t\t===================== create dylib =====================\n\n"
  cp -Rf $BUILD_DIR/lib $DIST_PACKAGE_DIR/
}

function createUnstrippedLibs() {
  printf "\n\n\t\t===================== create unstripped libs =====================\n\n"
  DIST_LIB_UNSTRIPPED_DIR="$DIST_PACKAGE_DIR/lib.unstripped/v8-ios/$VERSION"
  mkdir -p $DIST_LIB_UNSTRIPPED_DIR
  tar cfJ $DIST_LIB_UNSTRIPPED_DIR/libs.tar.xz -C $BUILD_DIR/lib.unstripped .
  unset DIST_LIB_UNSTRIPPED_DIR
}

function copyHeaders() {
  printf "\n\n\t\t===================== adding headers to $DIST_PACKAGE_DIR/include =====================\n\n"
  cp -Rf $V8_DIR/include $DIST_PACKAGE_DIR/include
}

function copyTools() {
  printf "\n\n\t\t===================== adding tools to $DIST_PACKAGE_DIR/tools =====================\n\n"
  cp -Rf $BUILD_DIR/tools $DIST_PACKAGE_DIR/tools
}


if [[ ${MKSNAPSHOT_ONLY} -eq "1" ]]; then
  mkdir -p $DIST_PACKAGE_DIR
  copyTools
else
  mkdir -p $DIST_PACKAGE_DIR
  copyLib
  createUnstrippedLibs
  copyHeaders
  copyTools
fi
