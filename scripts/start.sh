#!/bin/bash -e
source $(dirname $0)/env.sh

if [[ -d "${BUILD_DIR}" ]]; then
  rm -rf "${BUILD_DIR}"
fi

cd "${V8_DIR}"

if [[ ${MKSNAPSHOT_ONLY} = "true" ]]; then
  gclient sync --reset --with_branch_head --revision ${V8_VERSION}
elif [[ ${MKCODECACHE_ONLY} = "true" ]]; then
  gclient sync --deps=android --reset --with_branch_head --revision ${V8_VERSION}
else
  gclient sync --deps=${PLATFORM} --reset --with_branch_head --revision ${V8_VERSION}
fi

cd "${ROOT_DIR}"
scripts/patch.sh ${PLATFORM}

scripts/build.sh ${PLATFORM}
scripts/archive.sh ${PLATFORM}

if [[ ${TOOLS_ONLY} != "true" ]]; then
  NO_INTL=true scripts/build.sh ${PLATFORM}
  NO_INTL=true scripts/archive.sh ${PLATFORM}
fi
