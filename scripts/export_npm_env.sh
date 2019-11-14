#!/bin/bash -e
if [[ ${CIRCLECI} ]]; then
  echo "export VERSION=${npm_package_version}" >> $BASH_ENV
  echo "export V8_VERSION=${npm_package_config_V8}" >> $BASH_ENV
elif [[ ${GITHUB_ACTIONS} ]]; then
  echo "::set-env name=VERSION::${npm_package_version}"
  echo "::set-env name=V8_VERSION::${npm_package_config_V8}"
else
  export VERSION=${npm_package_version}
  export V8_VERSION=${npm_package_config_V8}
fi

export
