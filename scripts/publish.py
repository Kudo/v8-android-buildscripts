#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import sys

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
PACKAGES = ('v8-android', 'v8-android-nointl')


def parse_args():
    arg_parser = argparse.ArgumentParser()

    arg_parser.add_argument('--dry-run',
                            action='store_true',
                            help='Dry run mode for npm publish')
    arg_parser.add_argument('--tag',
                            '-T',
                            type=str,
                            required=True,
                            help='NPM published tag')
    arg_parser.add_argument('dist_tar_file',
                            action='store',
                            help='dist.tgz created from CI')

    args = arg_parser.parse_args()
    if not args.dist_tar_file:
        arg_parser.print_help()
        sys.exit(1)
    return args


def main():
    args = parse_args()

    workdir = os.path.join(ROOT_DIR, 'build', 'publish')
    if not os.path.exists(workdir):
        os.makedirs(workdir)
    subprocess.run(
        ['tar', '-xf', args.dist_tar_file, '-C', workdir])

    for package in PACKAGES:
        print('\n\n========== Publish {} package =========='.format(package))
        cwd = os.path.join(ROOT_DIR, 'packages', package)
        source_dir_in_tar_file = os.path.join(workdir, 'dist', 'packages', package)
        distdir = os.path.join(cwd, 'dist')
        if os.path.exists(distdir):
            shutil.rmtree(distdir)
        shutil.move(source_dir_in_tar_file, distdir)
        cmds = ['npm', 'publish', '--tag', args.tag]
        if args.dry_run:
            cmds.append('--dry-run')
        subprocess.run(cmds, cwd=cwd)

    shutil.rmtree(workdir)


if __name__ == '__main__':
    main()
