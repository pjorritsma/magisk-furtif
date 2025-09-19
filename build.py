#!/user/bin/env python3
import lzma
import os
import shutil
import zipfile


PATH_BASE = os.path.abspath(os.path.dirname(__file__))
PATH_BASE_MODULE = os.path.join(PATH_BASE, "base")
PATH_BUILDS = os.path.join(PATH_BASE, "builds")


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
author=Furtif and f3ger
description=Runs Apk-Tools on boot with magisk.
updateJson=https://raw.githubusercontent.com/f3ger/magisk-furtif/refs/heads/main/updater.json
minMagisk=1530""".format(frida_release, frida_release.replace(".", ""))

    with open(os.path.join(path, "module.prop"), "w", newline='\n') as f:
        f.write(module_prop)


def create_module(frida_release):
    # Create directory.
    module_dir = os.path.join(PATH_BUILDS)
    module_zip = os.path.join(PATH_BUILDS, "MagiskFurtif-f3ger-{0}.zip".format(frida_release))

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

    file_list = ["install.sh", "module.prop", "service.sh", "post-fs-data.sh", "system.prop"]
    
    # Add init.d script
    traverse_path_to_list(file_list, "./system")

    # Add all files from META-INF directory
    traverse_path_to_list(file_list, "./META-INF")

    print("Files to include in ZIP:")
    for file_name in file_list:
        print(f"  - {file_name}")

    with zipfile.ZipFile(module_zip, "w") as zf:
        for file_name in file_list:
            path = os.path.join(module_dir, file_name)

            if not os.path.exists(path):
                print("File {0} does not exist..".format(path))
                continue

            print(f"Adding to ZIP: {file_name}")
            zf.write(path, arcname=file_name)


def main():
    # Create necessary folders.
    if not os.path.exists(PATH_BUILDS):
        os.makedirs(PATH_BUILDS)
    
    # Create base directory if it doesn't exist
    if not os.path.exists(PATH_BASE_MODULE):
        os.makedirs(PATH_BASE_MODULE)
        os.makedirs(os.path.join(PATH_BASE_MODULE, "common"))
        os.makedirs(os.path.join(PATH_BASE_MODULE, "system"))
        os.makedirs(os.path.join(PATH_BASE_MODULE, "META-INF"))

# Fetch frida information.
frida_release = "3.3.1"

print("MagiskFurtif version is {0}.".format(frida_release))

# Create flashable modules.
create_module(frida_release)

print("Done.")


if __name__ == "__main__":
    main()
