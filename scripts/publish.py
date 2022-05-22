#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import sys

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
PACKAGE_MAP = {
    "v8-android": "dist-intl.zip",
    "v8-android-nointl": "dist-nointl.zip",
    "v8-android-jit": "dist-jit-intl.zip",
    "v8-android-jit-nointl": "dist-jit-nointl.zip",
}

MACOS_TOOLS_DIST_MAP = {
    "v8-android": "macos-tools-intl.zip",
    "v8-android-nointl": "macos-tools-nointl.zip",
    "v8-android-jit": "macos-tools-jit-intl.zip",
    "v8-android-jit-nointl": "macos-tools-jit-nointl.zip",
}


def parse_args():
    arg_parser = argparse.ArgumentParser()

    arg_parser.add_argument(
        "--dry-run", action="store_true", help="Dry run mode for npm publish"
    )
    arg_parser.add_argument(
        "--tag", "-T", type=str, required=True, help="NPM published tag"
    )
    arg_parser.add_argument(
        "distdir", action="store", help="dir to dist*.zip files created from CI"
    )

    args = arg_parser.parse_args()
    if not args.distdir:
        arg_parser.print_help()
        sys.exit(1)
    return args


def publish_engines(args, workdir):
    for (package, distfile) in PACKAGE_MAP.items():
        print("\n\n========== Publish {} package ==========".format(package))
        if os.path.exists(workdir):
            shutil.rmtree(workdir)
        os.makedirs(workdir)

        distfile_path = os.path.join(args.distdir, distfile)
        if not os.path.exists(distfile_path):
            raise FileNotFoundError("dist file not found: {}".format(distfile_path))
        subprocess.run(["unzip", distfile_path, "-d", workdir])

        cwd = os.path.join(ROOT_DIR, "packages", package)
        source_dir_in_zip_file = os.path.join(workdir, "dist", "packages", package)
        distfile_path = os.path.join(workdir, "dist.tar")
        subprocess.run(["tar", "-xf", distfile_path, "-C", workdir])
        distdir = os.path.join(cwd, "dist")
        if os.path.exists(distdir):
            shutil.rmtree(distdir)
        shutil.move(source_dir_in_zip_file, distdir)

        # remove unstripped lib and tools from npm and upload to github releases
        shutil.rmtree(os.path.join(distdir, "lib.unstripped"))
        shutil.rmtree(os.path.join(distdir, "tools"))

        cmds = ["npm", "publish", "--tag", args.tag]
        if args.dry_run:
            cmds.append("--dry-run")
        subprocess.run(cmds, cwd=cwd)

    shutil.rmtree(workdir)


def publish_tools_macos(args, workdir):
    print("\n\n========== Publish v8-android-tools-macos package ==========")
    pkg_root = os.path.join(ROOT_DIR, "packages", "v8-android-tools-macos")

    for (package, distfile) in MACOS_TOOLS_DIST_MAP.items():
        if os.path.exists(workdir):
            shutil.rmtree(workdir)
        os.makedirs(workdir)

        distfile_path = os.path.join(args.distdir, distfile)
        if not os.path.exists(distfile_path):
            raise FileNotFoundError("dist file not found: {}".format(distfile_path))

        subprocess.run(["unzip", distfile_path, "-d", workdir])
        source_dir_in_zip_file = os.path.join(
            workdir, "dist", "packages", "v8-android-tools", "tools", "macos_android"
        )
        distfile_path = os.path.join(workdir, "dist.tar")
        subprocess.run(["tar", "-xf", distfile_path, "-C", workdir])
        distdir = os.path.join(pkg_root, package)
        if os.path.exists(distdir):
            shutil.rmtree(distdir)
        shutil.move(source_dir_in_zip_file, distdir)

    # clear attributes
    subprocess.run(["xattr", "-r", "-d", "com.apple.quarantine", pkg_root])
    subprocess.run(
        ["xattr", "-r", "-d", "com.apple.metadata:kMDItemWhereFroms", pkg_root]
    )

    # publish
    cmds = ["npm", "publish", "--tag", args.tag]
    if args.dry_run:
        cmds.append("--dry-run")
    subprocess.run(cmds, cwd=pkg_root)

    shutil.rmtree(workdir)


def create_engines_zip(args, workdir):
    print("\n\n========== Create v8-android-tools-linux zip ==========")

    for (package, distfile) in PACKAGE_MAP.items():
        distfile_path = os.path.join(args.distdir, distfile)
        zip_filename = "{}.zip".format(package)
        shutil.copyfile(distfile_path, os.path.join(ROOT_DIR, zip_filename))


def create_tools_zip_macos(args, workdir):
    print("\n\n========== Create v8-android-tools-macos.zip ==========")
    pkg_root = os.path.join(ROOT_DIR, "packages", "v8-android-tools-macos")

    for (package, distfile) in MACOS_TOOLS_DIST_MAP.items():
        if os.path.exists(workdir):
            shutil.rmtree(workdir)
        os.makedirs(workdir)

        distfile_path = os.path.join(args.distdir, distfile)
        if not os.path.exists(distfile_path):
            raise FileNotFoundError("dist file not found: {}".format(distfile_path))

        subprocess.run(["unzip", distfile_path, "-d", workdir])
        source_dir_in_zip_file = os.path.join(
            workdir, "dist", "packages", "v8-android-tools", "tools", "macos_android"
        )
        distfile_path = os.path.join(workdir, "dist.tar")
        subprocess.run(["tar", "-xf", distfile_path, "-C", workdir])
        distdir = os.path.join(pkg_root, package)
        if os.path.exists(distdir):
            shutil.rmtree(distdir)
        shutil.move(source_dir_in_zip_file, distdir)

    # clear attributes
    subprocess.run(["xattr", "-r", "-d", "com.apple.quarantine", pkg_root])
    subprocess.run(
        ["xattr", "-r", "-d", "com.apple.metadata:kMDItemWhereFroms", pkg_root]
    )

    # publish
    cmds = ["zip", "-r", os.path.join(ROOT_DIR, "v8-android-tools-macos.zip"), "."]
    subprocess.run(cmds, cwd=pkg_root)

    shutil.rmtree(workdir)


def create_tools_zip_linux(args, workdir):
    print("\n\n========== Create v8-android-tools-linux zip ==========")
    pkg_root = os.path.join(ROOT_DIR, "packages", "v8-android-tools-linux")

    for (package, distfile) in PACKAGE_MAP.items():
        if os.path.exists(workdir):
            shutil.rmtree(workdir)
        os.makedirs(workdir)

        distfile_path = os.path.join(args.distdir, distfile)
        if not os.path.exists(distfile_path):
            raise FileNotFoundError("dist file not found: {}".format(distfile_path))

        subprocess.run(["unzip", distfile_path, "-d", workdir])
        source_dir_in_zip_file = os.path.join(
            workdir, "dist", "packages", package, "tools", "android"
        )
        distfile_path = os.path.join(workdir, "dist.tar")
        subprocess.run(["tar", "-xf", distfile_path, "-C", workdir])
        distdir = os.path.join(pkg_root, package)
        if os.path.exists(distdir):
            shutil.rmtree(distdir)
        shutil.move(source_dir_in_zip_file, distdir)

    # clear attributes
    subprocess.run(["xattr", "-r", "-d", "com.apple.quarantine", pkg_root])
    subprocess.run(
        ["xattr", "-r", "-d", "com.apple.metadata:kMDItemWhereFroms", pkg_root]
    )

    # zip
    cmds = ["zip", "-r", os.path.join(ROOT_DIR, "v8-android-tools-linux.zip"), "."]
    subprocess.run(cmds, cwd=pkg_root)

    shutil.rmtree(workdir)


def main():
    args = parse_args()
    workdir = os.path.join(ROOT_DIR, "build", "publish")
    publish_engines(args, workdir)
    publish_tools_macos(args, workdir)

    create_engines_zip(args, workdir)
    create_tools_zip_macos(args, workdir)
    create_tools_zip_linux(args, workdir)


if __name__ == "__main__":
    main()
