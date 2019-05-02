#!/bin/bash -e
source $(dirname $0)/env.sh

GCLIENT_SYNC_ARGS="--reset --with_branch_head"
while getopts 'r:s' opt; do
    case ${opt} in
        r)
            GCLIENT_SYNC_ARGS+=" --revision $OPTARG"
            ;;
        s)
            GCLIENT_SYNC_ARGS+=" --no-history"
            ;;
    esac
done


if [[ ! -d "$DEPOT_TOOLS_DIR" || ! -f "$DEPOT_TOOLS_DIR/gclient" ]]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_DIR
fi

gclient config --name v8 --unmanaged "https://chromium.googlesource.com/v8/v8.git"
gclient sync --deps=android $GCLIENT_SYNC_ARGS
sudo bash -c 'v8/build/install-build-deps-android.sh'

# Workaround to install missing sysroot
gclient sync
