#!/bin/bash -e
source $(dirname $0)/env.sh

if [[ ! -d "$DEPOT_TOOLS_DIR" || ! -f "$DEPOT_TOOLS_DIR/gclient" ]]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_DIR
fi

gclient config --name v8 --unmanaged "https://chromium.googlesource.com/v8/v8.git"
# gclient sync --deps=android --reset --with_branch_head
gclient sync --deps=android --reset --with_branch_head --revision 7.4.288.21
sudo bash -c 'v8/build/install-build-deps-android.sh'

# Workaround to install missing sysroot
gclient sync
