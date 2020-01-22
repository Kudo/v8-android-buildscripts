#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import sys

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
PACKAGE_MAP = {
    'v8-android': 'dist.tgz',
    'v8-android-nointl': 'dist-nointl.tgz',
    'v8-android-jit': 'dist-jit.tgz',
    'v8-android-jit-nointl': 'dist-jit-nointl.tgz',
}


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
    arg_parser.add_argument('distdir',
                            action='store',
                            help='dir to dist*.tgz files created from CI')

    args = arg_parser.parse_args()
    if not args.distdir:
        arg_parser.print_help()
        sys.exit(1)
    return args


def main():
    args = parse_args()

    workdir = os.path.join(ROOT_DIR, 'build', 'publish')

    for (package, distfile) in PACKAGE_MAP.items():
        print('\n\n========== Publish {} package =========='.format(package))
        if os.path.exists(workdir):
            shutil.rmtree(workdir)
        os.makedirs(workdir)

        distfile_path = os.path.join(args.distdir, distfile)
        if not os.path.exists(distfile_path):
            raise FileNotFoundError(
                'dist file not found: {}'.format(distfile_path))
        subprocess.run(['tar', '-xf', distfile_path, '-C', workdir])

        cwd = os.path.join(ROOT_DIR, 'packages', package)
        source_dir_in_tar_file = os.path.join(workdir, 'dist', 'packages',
                                              package)
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
