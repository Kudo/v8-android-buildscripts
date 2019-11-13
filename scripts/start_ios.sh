#!/bin/bash -e
source $(dirname $0)/env.sh

cd $V8_DIR

if [[ ${MKSNAPSHOT_ONLY} -eq "1" ]]; then
  gclient sync --reset --with_branch_head --revision ${V8_VERSION}
else
  gclient sync --deps=ios --reset --with_branch_head --revision ${V8_VERSION}
fi

cd $ROOT_DIR
scripts/patch_ios.sh

scripts/build_ios.sh
scripts/archive_ios.sh

# NO_INTL=1 scripts/build_ios.sh
# NO_INTL=1 scripts/archive_ios.sh
