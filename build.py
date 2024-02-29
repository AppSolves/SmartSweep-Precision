# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the necessary modules and classes
import base64
import json
import os
import shutil
import zipfile
from hashlib import sha256
from typing import Annotated, Optional

import typer
from cryptography.fernet import Fernet, InvalidToken

from classes import Color

# Global variables to store some options and paths
excl_config = False
app = typer.Typer()
self_file = os.path.basename(__file__)
this_dir = os.path.dirname(os.path.realpath(__file__))

# Callback to store the exclude-config option
@app.callback()
def main(
    exclude_config: Annotated[
        Optional[bool],
        typer.Option(
            ...,
            "--exclude-config",
            "-ec",
            help="Exclude config files when building or syncing the firmware",
        ),
    ] = False,
):
    global excl_config
    excl_config = exclude_config

# Exclude files and directories when syncing or building the firmware
exclude_files = [
    self_file,
    "README.md",
    ".gitignore",
    "requirements.txt",
    "classes.py",
    "ble_secrets.json" if excl_config else None,
]
exclude_dirs = [
    "System Volume Information",
    ".vscode",
    ".venv",
    ".git",
    "__pycache__",
    "app",
    "assets",
    "build",
    "config" if excl_config else None,
]

# Helper function to change the firmware version
def __change_version__(increase: bool = True):
    with open(os.path.join(this_dir, "info.json")) as f:
        try:
            # Load the `info.json` file
            info = json.load(f)
        except json.JSONDecodeError:
            # If the file is empty or corrupted, create a new dictionary
            info = {}
        if info.get("firmware_version", None) is None:
            # If the firmware version is not defined, set it to 1.0.0
            info["firmware_version"] = "1.0.0"
        else:
            # Increase or decrease the version based on the increase parameter
            major, minor, patch = map(int, info["firmware_version"].split("."))
            if increase:
                patch += 1
                if patch == 10:
                    patch = 0
                    minor += 1
                    if minor == 10:
                        minor = 0
                        major += 1
            else:
                patch -= 1
                if patch == -1:
                    patch = 9
                    minor -= 1
                    if minor == -1:
                        minor = 9
                        major -= 1
            # Overwrite the firmware version with the new version in the info dictionary
            info["firmware_version"] = f"{major}.{minor}.{patch}"
    with open(os.path.join(this_dir, "info.json"), "w") as f:
        # Write the new version to the `info.json` file
        json.dump(info, f, indent=4)

# Helper function to get the firmware version
def __get_version__():
    with open(os.path.join(this_dir, "info.json")) as f:
        # Load the `info.json` file and return the firmware version
        try:
            info = json.load(f)
        except json.JSONDecodeError:
            # If the file is empty or corrupted, create a new dictionary
            info = {}
        return info.get("firmware_version", "1.0.0")

# Main command to sync the firmware to an Arduino drive
@app.command(help="Sync the firmware to an Arduino drive")
def sync(
    # Define CLI arguments and options
    disk: Annotated[
        str,
        typer.Argument(...,
            help=f"The drive letter to sync to (e.g. '{Color.colorize("P", Color.PURPLE)}')",
            show_default=False,
        ),
    ],
    from_zip_path: Annotated[
        Optional[str],
        typer.Option(
            ...,
            "--zip",
            "-z",
            show_default=False,
            help=f"Sync from a zip file containing the firmware instead of the current directory (e.g. '{Color.colorize("C:/path/to/firmware.zip", Color.PURPLE)}')",
        ),
    ] = None,
    password: Annotated[
        Optional[str],
        typer.Option(
            ...,
            "--password",
            "-p",
            show_default=False,
            help=f"The password to decrypt the firmware file (If it was encrypted, e.g. '{Color.colorize("password123", Color.CYAN)}')",
        ),
    ] = None,
):
    arduino_dir = rf"{disk}:"

    # Check if the drive exists
    if not os.path.exists(arduino_dir):
        typer.echo(f"\n{Color.colorize("ERROR", Color.RED)}: Drive '{Color.colorize(f"{disk}:\\", Color.PURPLE)}' does not exist\n")
        raise typer.Exit(code=1)

    try:
        # Delete all files and directories in the Arduino drive
        for root, dirs, files in os.walk(arduino_dir, topdown=False):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]

            for name in files:
                os.remove(os.path.join(root, name))
            for name in dirs:
                os.rmdir(os.path.join(root, name))

        # Sync the firmware to the Arduino drive
        if not from_zip_path:
            # Iterate through the current directory and copy the files to the Arduino drive
            for root, dirs, files in os.walk(this_dir):
                # Exclude the files and directories defined in the `exclude_files` and `exclude_dirs` lists
                dirs[:] = [d for d in dirs if d not in exclude_dirs]
                files[:] = [f for f in files if f not in exclude_files]

                for dir in dirs:
                    dir_path = os.path.join(root, dir)
                    relative_path = os.path.relpath(dir_path, this_dir)
                    shutil.copytree(dir_path, os.path.join(arduino_dir, relative_path))

                for file in files:
                    file_path = os.path.join(root, file)
                    relative_path = os.path.relpath(file_path, this_dir)
                    os.makedirs(
                        os.path.dirname(os.path.join(arduino_dir, relative_path)),
                        exist_ok=True,
                    )
                    shutil.copy(file_path, os.path.join(arduino_dir, relative_path))
        else:
            # Extract the zip file to the Arduino drive
            if password:
                # Decrypt the zip file if the `password` is provided
                with open(from_zip_path, "rb") as f:
                    data = f.read()
                hash_clipped_pwd = sha256(password.encode()).digest()[:32]
                key = base64.urlsafe_b64encode(hash_clipped_pwd)
                fernet = Fernet(key)
                data = fernet.decrypt(data)
                with open(from_zip_path, "wb") as f:
                    f.write(data)

            # Extract the zip file to the Arduino drive
            with zipfile.ZipFile(from_zip_path, "r") as zipf:
                zipf.extractall(arduino_dir)

            # Encrypt the zip file again if the `password` is provided
            if password:
                with open(from_zip_path, "wb") as f:
                    f.write(fernet.encrypt(data))

        # Print out the success messages
        typer.echo("\nSync complete!\n")

        if excl_config:
            typer.echo(f"{Color.colorize("NOTE", Color.CYAN)}: Config files were not synced\n")

    # When an error occurs, print the error and exit
    except zipfile.BadZipFile:
        typer.echo(f"\n{Color.colorize('ERROR', Color.RED)}: Invalid zip file! Maybe it's corrupted or encrypted...")
        typer.echo(f"{Color.colorize('INFO', Color.BLUE)}: If the file is encrypted, you can use the '{Color.colorize('--password', Color.CYAN)}' option to decrypt it\n")
        raise typer.Exit(code=1)
    except InvalidToken:
        typer.echo(f"\n{Color.colorize('ERROR', Color.RED)}: Invalid password! The file might be corrupted or the password is wrong\n")
        raise typer.Exit(code=1)
    except Exception as e:
        typer.echo(f"\n{Color.colorize("ERROR", Color.RED)}: {e}\n")
        raise typer.Exit(code=1)

# Main command to build the firmware into a zip file
@app.command(
    help=f"Build the firmware into a zip file (Output: '{Color.colorize('build/SSP_firmware.zip', Color.PURPLE)}')"
)
def build(
    # Optional option to encrypt the firmware file
    encrypt: Annotated[
        Optional[str],
        typer.Option(
            ...,
            "--encrypt",
            "-e",
            show_default=False,
            help=f"Encrypt the firmware file with a password ({Color.colorize("Min. 8 characters", Color.GREEN)}, e.g. '{Color.colorize("password123", Color.CYAN)}')",
        ),
    ] = None,
    next_version: Annotated[
        Optional[bool],
        typer.Option(
            ...,
            "--next-version",
            "-nv",
            help="Increase the version before building the firmware",
        ),
    ] = False,
):
    # Check if the password is at least 8 characters long
    if encrypt and len(encrypt) < 8:
        typer.echo(f"\n{Color.colorize('ERROR', Color.RED)}: Password must be at least 8 characters long!\n")
        raise typer.Exit(code=1)
    
    try:
        # If `next_version` is true, increase the version.
        if next_version:
            __change_version__()
        # Delete the build directory and create a new one
        shutil.rmtree(os.path.join(this_dir, "build"), ignore_errors=True)
        os.makedirs(os.path.join(this_dir, "build"), exist_ok=True)
        with zipfile.ZipFile(
            os.path.join(this_dir, "build", f"SSP_firmware_v{__get_version__()}.zip"),
            "w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=9,
        ) as zipf:
            # Iterate through the current directory and add the files to the zip file
            for root, dirs, files in os.walk(this_dir):
                # Exclude the files and directories defined in the `exclude_files` and `exclude_dirs` lists
                dirs[:] = [d for d in dirs if d not in exclude_dirs]
                files[:] = [f for f in files if f not in exclude_files]

                for file in files:
                    file_path = os.path.join(root, file)
                    relative_path = os.path.relpath(file_path, this_dir)
                    zipf.write(file_path, relative_path)

        # Encrypt the firmware file if the `encrypt` option is provided
        if encrypt:
            with open(os.path.join(this_dir, "build", f"SSP_firmware_v{__get_version__()}.zip"), "rb") as f:
                data = f.read()
            hash_clipped_pwd = sha256(encrypt.encode()).digest()[:32]
            key = base64.urlsafe_b64encode(hash_clipped_pwd)
            fernet = Fernet(key)
            encrypted = fernet.encrypt(data)
            with open(os.path.join(this_dir, "build", f"SSP_firmware_v{__get_version__()}.zip"), "wb") as f:
                f.write(encrypted)

        # Print out the success messages
        typer.echo("\nBuild complete!")
        typer.echo(
            f"Output: {Color.colorize(os.path.join(this_dir, 'build', f"SSP_firmware_v{__get_version__()}.zip"), Color.PURPLE)}\n"
        )
        if encrypt:
            hidden_pwd = Color.colorize("*" * len(encrypt[:-3]) + encrypt[-3:], Color.PURPLE)
            typer.echo(f"{Color.colorize('NOTE', Color.CYAN)}: Firmware file was encrypted")
            typer.echo(f"{Color.colorize('WARNING', Color.YELLOW)}: Do not forget the password!: {hidden_pwd} | If you lose it, the firmware file will be useless!\n")
    except Exception as e:
        # When an error occurs, decrease the version again (if `next_version` was true), print the error and exit
        if next_version:
            __change_version__(increase=False)
        typer.echo(f"\n{Color.colorize("ERROR", Color.RED)}: {e}\n")
        raise typer.Exit(code=1)

# Main command to clean the build directory
@app.command(help="Clean the build directory")
def clean():
    try:
        # Delete the build directory and the `__pycache__` directory
        shutil.rmtree(os.path.join(this_dir, "build"), ignore_errors=True)
        shutil.rmtree(os.path.join(this_dir, "__pycache__"), ignore_errors=True)
        typer.echo("\nClean complete!\n")
    except Exception as e:
        # When an error occurs, print the error and exit
        typer.echo(f"\n{Color.colorize("ERROR", Color.RED)}: {e}\n")
        raise typer.Exit(code=1)

# Main command to print out the firmware version
@app.command(help="Print the current firmware version and exit")
def version():
    typer.echo(
        f"\nSmartSweep Precision: Firmware {Color.colorize(f'v{__get_version__()}', Color.CYAN)}\n"
    )

# Run the CLI
if __name__ == "__main__":
    app()
