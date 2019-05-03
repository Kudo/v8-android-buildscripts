#!/bin/bash -e
source $(dirname $0)/env.sh

cd $V8_DIR
gclient sync --deps=android --reset --with_branch_head --revision ${V8_VERSION}

cd $ROOT_DIR
scripts/patch.sh
scripts/build.sh
scripts/archive.sh
