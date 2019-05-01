#!/bin/bash -e

function abs_path()
{
    readlink="readlink -f"
    if [[ "$(uname)" == "Darwin" ]]; then
        if [[ ! "$(command -v greadlink)" ]]; then
            echo "greadlink not found. Please install greadlink by \`brew install coreutils\`"
            exit 1
        fi
      readlink="greadlink -f"
    fi

    echo `$readlink $1`
}

CURR_DIR=$(dirname $(abs_path $0))
ROOT_DIR=$(dirname $CURR_DIR)
unset CURR_DIR

DEPOT_TOOLS_DIR=$ROOT_DIR/scripts/depot_tools
V8_DIR=$ROOT_DIR/v8
DIST_DIR=$ROOT_DIR/dist
PATCHES_DIR=$ROOTDIR/patches

export PATH="$DEPOT_TOOLS_DIR:$PATH"
