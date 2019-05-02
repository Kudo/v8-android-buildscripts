#!/bin/bash -e

export VERSION=${npm_package_version}
echo "export VERSION=${npm_package_version}"

export V8_VERSION=${npm_package_config_V8}
echo "export V8_VERSION=${npm_package_config_V8}"
