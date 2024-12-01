#!/user/bin/env python3
import argparse
import os
import shutil
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument("-n", "--name", type=str, help="Name for clone.")
parser.add_argument("-c", "--clone", type=int, help="Number for clones.")
args = parser.parse_args()
# Set defaults args
name = args.name or None
clones = args.clone or 0

PATH_BASE = os.path.abspath(os.path.dirname(__file__))
PATH_BASE_MODULE = os.path.join(PATH_BASE, "base")
PATH_BUILDS = os.path.join(PATH_BASE, "builds")
PATH_CLONES = os.path.join(PATH_BASE, "clones")
SERVICE_FILE = os.path.join(PATH_BUILDS, "common", "service.sh")


def replace_device_name_in_service(device_name):
    with open(SERVICE_FILE, "r") as f:
        lines = f.readlines()

    with open(SERVICE_FILE, "w") as f:
        for line in lines:
            if line.startswith("DEVICENAME="):
                f.write(f'DEVICENAME="{device_name}"\n')
            else:
                f.write(line)


def traverse_path_to_list(file_list, path):
    for dp, dn, fn in os.walk(path):
        for f in fn:
            if f == "placeholder" or f == ".gitkeep":
                continue
            file_list.append(os.path.join(dp, f))


def create_module_prop(path, frida_release):
    # Create module.prop file.
    module_prop = """id=magiskfurtif
name=MagiskFurtif
version=v{0}
versionCode={1}
author=Furtif
description=Runs FurtiF Tools on boot with magisk.
support=https://github.com/Furtif/magisk-furtif/issues
minMagisk=1530""".format(frida_release, frida_release.replace(".", ""))

    with open(os.path.join(path, "module.prop"), "w", newline='\n') as f:
        f.write(module_prop)


def create_module(frida_release):
    # Create directory.
    module_dir = os.path.join(PATH_BUILDS)
    module_zip = os.path.join(PATH_BUILDS, "MagiskFurtif-{0}.zip".format(frida_release))

    if os.path.exists(module_dir):
        shutil.rmtree(module_dir)

    if os.path.exists(module_zip):
        os.remove(module_zip)

    # Copy base module into module dir.
    shutil.copytree(PATH_BASE_MODULE, module_dir)

    # cd into module directory.
    os.chdir(module_dir)

    # Create module.prop.
    create_module_prop(module_dir, frida_release)

    # Create flashable zip.
    print("Building Magisk module.")

    file_list = ["install.sh", "module.prop"]

    traverse_path_to_list(file_list, "./common")
    traverse_path_to_list(file_list, "./system")
    traverse_path_to_list(file_list, "./META-INF")

    if name is not None and clones > 1:
        for i in range(1, clones + 1):
            device_name = "{0}-{1}".format(name, i)
            replace_device_name_in_service(device_name)
            module_zip = os.path.join(PATH_CLONES, "MagiskFurtif-{0}-{1}.zip".format(frida_release, device_name))
            with zipfile.ZipFile(module_zip, "w") as zf:
                for file_name in file_list:
                    path = os.path.join(module_dir, file_name)
                    if not os.path.exists(path):
                        print("File {0} does not exist..".format(path))
                        continue
                    zf.write(path, arcname=file_name)
    elif name is not None and (clones == 0 or clones == 1):
        device_name = "{0}".format(name)
        replace_device_name_in_service(device_name)
        module_zip = os.path.join(PATH_CLONES, "MagiskFurtif-{0}-{1}.zip".format(frida_release, device_name))
        with zipfile.ZipFile(module_zip, "w") as zf:
            for file_name in file_list:
                path = os.path.join(module_dir, file_name)
                if not os.path.exists(path):
                    print("File {0} does not exist..".format(path))
                    continue
                zf.write(path, arcname=file_name)                     
    else:
        with zipfile.ZipFile(module_zip, "w") as zf:
            for file_name in file_list:
                path = os.path.join(module_dir, file_name)
                if not os.path.exists(path):
                    print("File {0} does not exist..".format(path))
                    continue
                zf.write(path, arcname=file_name)


def main():
    # Create necessary folders.
    if not os.path.exists(PATH_BUILDS):
        os.makedirs(PATH_BUILDS)
    # Clean clones dir
    if os.path.exists(PATH_CLONES):
        shutil.rmtree(PATH_CLONES)
    if not os.path.exists(PATH_CLONES):
        os.makedirs(PATH_CLONES)

    # Fetch frida information.
    frida_release = "1.6"

    print("MagiskFurtif version is {0}.".format(frida_release))
        
    # Create flashable modules.
    create_module(frida_release)

    print("Done.")


if __name__ == "__main__":
    main()
