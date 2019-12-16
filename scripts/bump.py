#!/usr/bin/env python3
from __future__ import unicode_literals
import argparse
import io
import os
import re
import sys

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
PACKAGES = ('v8-android', 'v8-android-nointl')


class PackageConfigPatcher:
    def __init__(self, root, version):
        self._config_path = os.path.join(root, 'package.json')
        self._version = version

    @classmethod
    def _replace_file_content(cls,
                              file_path,
                              old_pattern,
                              new_pattern,
                              re_flags=0):
        with io.open(file_path, 'r', encoding='utf8') as f:
            content = str(f.read())
            new_content = re.sub(old_pattern,
                                 new_pattern,
                                 content,
                                 flags=re_flags)
        with io.open(file_path, 'w', encoding='utf8') as f:
            f.write(new_content)

    def patch(self):
        self._replace_file_content(self._config_path,
                                   r'("version": )("[^"]+")(,)',
                                   '\\1"' + self._version + '"\\3')


def parse_args():
    arg_parser = argparse.ArgumentParser()

    arg_parser.add_argument('--version',
                            '-V',
                            type=str,
                            required=True,
                            help='Bump packages version')

    args = arg_parser.parse_args()
    return args


def main():
    args = parse_args()
    version = args.version

    PackageConfigPatcher(ROOT_DIR, version).patch()

    for package in PACKAGES:
        print('\nBump {} package to version {}'.format(package, version))
        package_root = os.path.join(ROOT_DIR, 'packages', package)
        PackageConfigPatcher(package_root, version).patch()


if __name__ == '__main__':
    main()
